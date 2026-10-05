// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import JavaScriptCore
import Darwin

private func armParserDeadline() {
    signal(SIGALRM, SIG_DFL)
    var alarms = sigset_t()
    sigemptyset(&alarms)
    sigaddset(&alarms, SIGALRM)
    // XPC dispatch threads may mask signals; unblock on the actual parser thread.
    sigprocmask(SIG_UNBLOCK, &alarms, nil)
    alarm(2)
}

private final class HighlighterService: NSObject, HighlighterProtocol {
    private let lock = NSLock()

    func highlight(_ source: String, language: String, withReply reply: @escaping @Sendable (String?) -> Void) {
        reply(parse(source, language: language))
    }

    private func parse(_ source: String, language: String) -> String? {
        guard source.utf8.count <= 32 * 1024, language.utf8.count <= 64,
              lock.lock(before: Date(timeIntervalSinceNow: 0.3)) else { return nil }
        // Allow a brief overlap when browsing; never queue behind a stuck parser.
        // The alarm also exits a stuck service after its preview host disappears.
        armParserDeadline()
        defer { alarm(0); lock.unlock() }
        guard let url = Bundle.main.url(forResource: "highlight.min", withExtension: "js"),
              let library = try? String(contentsOf: url, encoding: .utf8),
              let context = JSContext() else { return nil }
        context.evaluateScript(library)
        guard context.exception == nil else { return nil }
        let function = context.evaluateScript("""
        (function(source, language) {
          if (!hljs.getLanguage(language)) return null;
          return hljs.highlight(source, {language: language, ignoreIllegals: true}).value;
        })
        """)
        let value = function?.call(withArguments: [source, language])
        guard context.exception == nil, let value, value.isString,
              let result = value.toString(), result.utf8.count <= 1024 * 1024 else { return nil }
        return result
    }
}

private final class ServiceDelegate: NSObject, NSXPCListenerDelegate {
    private let service = HighlighterService()

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        connection.exportedInterface = NSXPCInterface(with: HighlighterProtocol.self)
        connection.exportedObject = service
        connection.resume()
        return true
    }
}

@main
struct HighlighterMain {
    static func main() {
        armParserDeadline()
        // WebKit requires its first initialization on the process's main thread.
        _ = JSContext()
        alarm(0)
        let delegate = ServiceDelegate()
        let listener = NSXPCListener.service()
        listener.delegate = delegate
        withExtendedLifetime(delegate) { listener.resume() }
    }
}
