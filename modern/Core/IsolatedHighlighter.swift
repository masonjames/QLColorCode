// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Darwin
import OSLog

/// A parser crash or stuck regular expression must not strand its preview host.
struct IsolatedHighlighter {
    static let outputLimit = 1024 * 1024
    let executable: URL?
    var budget: Duration = .seconds(1)

    func highlight(_ source: String, language: String, isCancelled: () -> Bool) -> String? {
        guard let executable, !isCancelled(), source.utf8.count <= 32 * 1024,
              let request = try? JSONEncoder().encode(HighlightRequest(source: source, language: language)) else { return nil }
        let input = Pipe()
        let output = Pipe()
        var pid: pid_t = 0
        var launched = false
        var reaped = false
        defer {
            if launched && !reaped {
                kill(pid, SIGKILL)
                while waitpid(pid, nil, 0) < 0 && errno == EINTR {}
            }
            for handle in [input.fileHandleForReading, input.fileHandleForWriting,
                           output.fileHandleForReading, output.fileHandleForWriting] {
                try? handle.close()
            }
        }
        let writer = input.fileHandleForWriting.fileDescriptor
        let reader = output.fileHandleForReading.fileDescriptor
        // Pipes must never block the deadline loop; a child exit must not SIGPIPE
        // the parent while it is still sending the request.
        guard fcntl(writer, F_SETFL, O_NONBLOCK) == 0,
              fcntl(reader, F_SETFL, O_NONBLOCK) == 0,
              fcntl(writer, F_SETNOSIGPIPE, 1) == 0 else { return nil }
        let clock = ContinuousClock()
        let deadline = clock.now + budget
        var actions: posix_spawn_file_actions_t?
        var attributes: posix_spawnattr_t?
        guard posix_spawn_file_actions_init(&actions) == 0 else { return nil }
        defer { posix_spawn_file_actions_destroy(&actions) }
        guard posix_spawnattr_init(&attributes) == 0 else { return nil }
        defer { posix_spawnattr_destroy(&attributes) }
        guard posix_spawnattr_setflags(&attributes, Int16(POSIX_SPAWN_CLOEXEC_DEFAULT)) == 0,
              posix_spawn_file_actions_adddup2(&actions, input.fileHandleForReading.fileDescriptor, STDIN_FILENO) == 0,
              posix_spawn_file_actions_adddup2(&actions, output.fileHandleForWriting.fileDescriptor, STDOUT_FILENO) == 0,
              posix_spawn_file_actions_addopen(&actions, STDERR_FILENO, "/dev/null", O_WRONLY, 0) == 0 else { return nil }
        let name = strdup(executable.path)!
        defer { free(name) }
        var arguments: [UnsafeMutablePointer<CChar>?] = [name, nil]
        var environment: [UnsafeMutablePointer<CChar>?] = [nil]
        guard posix_spawn(&pid, name, &actions, &attributes, &arguments, &environment) == 0 else {
            return failure("spawn")
        }
        launched = true
        try? input.fileHandleForReading.close()
        try? output.fileHandleForWriting.close()
        var sent = 0
        var inputClosed = false
        var received = Data()
        var chunk = [UInt8](repeating: 0, count: 8192)
        while true {
            guard !isCancelled() else { return failure("cancelled") }
            guard clock.now < deadline else { return failure("timeout") }
            if !inputClosed {
                let count = request.withUnsafeBytes { bytes in
                    Darwin.write(writer, bytes.baseAddress!.advanced(by: sent), bytes.count - sent)
                }
                if count > 0 { sent += count }
                else if count < 0 && errno != EAGAIN && errno != EINTR { return failure("input pipe") }
                if sent == request.count {
                    try? input.fileHandleForWriting.close()
                    inputClosed = true
                }
            }
            let count = chunk.withUnsafeMutableBytes { Darwin.read(reader, $0.baseAddress!, $0.count) }
            if count > 0 {
                guard received.count + count <= Self.outputLimit else { return failure("output limit") }
                received.append(contentsOf: chunk.prefix(count))
            } else if count == 0 {
                break
            } else if errno != EAGAIN && errno != EINTR {
                return nil
            }
            var descriptors = [pollfd(fd: reader, events: Int16(POLLIN), revents: 0),
                               pollfd(fd: inputClosed ? -1 : writer, events: Int16(POLLOUT), revents: 0)]
            if poll(&descriptors, nfds_t(descriptors.count), 10) < 0 && errno != EINTR { return nil }
        }
        var status: Int32 = 0
        while true {
            let result = waitpid(pid, &status, WNOHANG)
            if result == pid { reaped = true; break }
            if result < 0 && errno != EINTR {
                // A host that reaped the child already must never make us kill a reused PID.
                if errno == ECHILD { reaped = true }
                return failure("wait")
            }
            guard !isCancelled(), clock.now < deadline else { return failure("exit deadline") }
            // stdout may close before the helper exits. Keep this wait bounded too.
            _ = poll(nil, 0, 10)
        }
        guard status == 0, inputClosed, !isCancelled(),
              let text = String(data: received, encoding: .utf8) else { return failure("invalid result or crash") }
        return text
    }

    private func failure(_ reason: String) -> String? {
        Logger(subsystem: "org.masonjames.QLColorCode", category: "parser")
            .notice("Using plain text: \(reason, privacy: .public)")
        return nil
    }
}
