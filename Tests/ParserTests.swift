// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Darwin
import Synchronization

@main
struct ParserTests {
    static let fixture = "org.masonjames.QLColorCode.Tests.Fixture"

    static func main() throws {
        if CommandLine.arguments.contains("--orphan") { orphan(); return }
        let client = IsolatedHighlighter(serviceName: fixture)
        let clock = ContinuousClock()
        var checks = 0
        func expect(_ condition: Bool, _ label: String) throws {
            guard condition else { throw NSError(domain: "ParserTests", code: 1, userInfo: [NSLocalizedDescriptionKey: label]) }
            checks += 1
        }
        func run(_ source: String) -> String? { client.highlight(source, language: "swift", isCancelled: { false }) }
        let real = IsolatedHighlighter(serviceName: "org.masonjames.QLColorCode.Tests.Highlight")
        try expect(real.highlight("let x = 1", language: "swift", isCancelled: { false })?.contains("hljs-keyword") == true, "Actual XPC grammar highlights")
        try expect(run("error") == nil, "Parser exception falls back")
        try expect(run("oversize") == nil, "Oversize result falls back")
        try expect(run(String(repeating: "x", count: 32769)) == nil, "Oversize request falls back")
        try expect(run("ok") == "recovered", "Recovery after invalid output and exception")
        let (steady, service) = warmFixture()
        let initialPID = steady.processIdentifier
        Thread.sleep(forTimeInterval: 2.5)
        let stillReady = DispatchSemaphore(value: 0)
        service.highlight("ok", language: "swift") { if $0 == "recovered" { stillReady.signal() } }
        try expect(stillReady.wait(timeout: .now() + 1) == .success && steady.processIdentifier == initialPID,
                   "A successful request disarms its alarm")
        steady.invalidate()
        let done = DispatchSemaphore(value: 0)
        let outcome = Mutex<(String?, Duration)>((nil, .zero))
        DispatchQueue.global().async {
            let start = clock.now
            let result = client.highlight("loop", language: "swift", isCancelled: { false })
            outcome.withLock { $0 = (result, start.duration(to: clock.now)) }
            done.signal()
        }
        Thread.sleep(forTimeInterval: 0.2)
        let busy = clock.now
        try expect(run("ok") == nil, "Contention with a hung parser falls back")
        let busyElapsed = busy.duration(to: clock.now)
        try expect(busyElapsed >= .milliseconds(250) && busyElapsed < .milliseconds(700), "Contention wait is bounded")
        try expect(done.wait(timeout: .now() + 2) == .success, "Hung request returns")
        let (result, elapsed) = outcome.withLock { $0 }
        try expect(result == nil, "Hung parser falls back")
        try expect(elapsed >= .milliseconds(800) && elapsed < .seconds(1.5), "Real hung service reaches the parent deadline")
        func recover() -> Bool {
            // launchd throttles relaunch after a service exits. Previews still time out.
            let deadline = clock.now + .seconds(15)
            while clock.now < deadline {
                if run("ok") == "recovered" { return true }
                Thread.sleep(forTimeInterval: 0.2)
            }
            return false
        }
        try expect(recover(), "Service terminates the hang and launchd eventually restarts it")
        let cancel = clock.now
        try expect(client.highlight("loop", language: "swift", isCancelled: {
            cancel.duration(to: clock.now) >= .milliseconds(100)
        }) == nil, "In-flight cancellation")
        try expect(cancel.duration(to: clock.now) < .milliseconds(500), "Cancellation is prompt")
        try expect(recover(), "Service recovers after cancellation")
        let missing = IsolatedHighlighter(serviceName: "org.masonjames.QLColorCode.Tests.Missing")
        try expect(missing.highlight("x", language: "swift", isCancelled: { false }) == nil, "Unavailable service falls back")
        print("PASS: \(checks) real XPC parser checks; deadline, cancellation, exception, bounds and recovery")
    }

    // The Python test kills this host while its real XPC service is parsing.
    private static func orphan() {
        let (connection, service) = warmFixture()
        service.highlight("loop", language: "swift") { _ in }
        Thread.sleep(forTimeInterval: 0.2)
        print(connection.processIdentifier)
        fflush(stdout)
        withExtendedLifetime(connection) { Thread.sleep(forTimeInterval: 30) }
    }

    private static func warmFixture() -> (NSXPCConnection, HighlighterProtocol) {
        let connection = NSXPCConnection(serviceName: fixture)
        connection.remoteObjectInterface = NSXPCInterface(with: HighlighterProtocol.self)
        connection.resume()
        let ready = DispatchSemaphore(value: 0)
        let service = connection.remoteObjectProxyWithErrorHandler { _ in exit(1) } as! HighlighterProtocol
        service.highlight("ok", language: "swift") { result in
            guard result == "recovered" else { exit(1) }
            ready.signal()
        }
        guard ready.wait(timeout: .now() + 2) == .success, connection.processIdentifier > 0 else { exit(1) }
        return (connection, service)
    }
}
