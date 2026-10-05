// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Synchronization
import OSLog

/// Quick Look permits embedded XPC services, but cannot spawn child processes.
struct IsolatedHighlighter {
    var serviceName = "org.masonjames.QLColorCode.Highlight"

    func highlight(_ source: String, language: String, isCancelled: () -> Bool) -> String? {
        guard !isCancelled(), source.utf8.count <= 32 * 1024 else { return nil }
        let connection = NSXPCConnection(serviceName: serviceName)
        defer { connection.invalidate() }
        connection.remoteObjectInterface = NSXPCInterface(with: HighlighterProtocol.self)
        let response = Mutex<(finished: Bool, text: String?)>((false, nil))
        let ready = DispatchSemaphore(value: 0)
        let finish: @Sendable (String?) -> Void = { text in
            response.withLock { state in
                if !state.finished { state = (true, text) }
            }
            ready.signal()
        }
        connection.interruptionHandler = { finish(nil) }
        connection.invalidationHandler = { finish(nil) }
        connection.resume()
        guard let service = connection.remoteObjectProxyWithErrorHandler({ _ in finish(nil) }) as? HighlighterProtocol else {
            return nil
        }
        let clock = ContinuousClock()
        let deadline = clock.now + .seconds(1)
        service.highlight(source, language: language, withReply: finish)
        while !isCancelled() && clock.now < deadline {
            if ready.wait(timeout: .now() + .milliseconds(10)) == .success {
                let text = response.withLock { $0.text }
                if let text, text.utf8.count <= 1024 * 1024 { return text }
                return failure("service unavailable or invalid result")
            }
        }
        return failure(isCancelled() ? "cancelled" : "timeout")
    }

    private func failure(_ reason: String) -> String? {
        Logger(subsystem: "org.masonjames.QLColorCode", category: "parser")
            .notice("Using plain text: \(reason, privacy: .public)")
        return nil
    }
}
