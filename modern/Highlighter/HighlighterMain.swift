// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import JavaScriptCore
import Darwin

@main
struct HighlighterMain {
    static func main() {
        // Survive neither a stuck grammar nor a Quick Look host killed mid-preview.
        signal(SIGALRM, SIG_DFL)
        var alarms = sigset_t()
        sigemptyset(&alarms)
        sigaddset(&alarms, SIGALRM)
        sigprocmask(SIG_UNBLOCK, &alarms, nil)
        alarm(2)
        do { try highlight() } catch { exit(1) }
    }

    private static func highlight() throws {
        var input = Data()
        while let chunk = try FileHandle.standardInput.read(upToCount: 8192), !chunk.isEmpty {
            input.append(chunk)
            guard input.count <= 256 * 1024 else { exit(1) }
        }
        let request = try JSONDecoder().decode(HighlightRequest.self, from: input)
        guard request.source.utf8.count <= 32 * 1024, request.language.utf8.count <= 64 else { exit(1) }
        let resources = URL(fileURLWithPath: CommandLine.arguments[0])
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Resources")
        let library = try String(contentsOf: resources.appendingPathComponent("highlight.min.js"), encoding: .utf8)
        guard let context = JSContext() else { exit(1) }
        context.evaluateScript(library)
        guard context.exception == nil else { exit(1) }
        let function = context.evaluateScript("""
        (function(source, language) {
          if (!hljs.getLanguage(language)) return null;
          return hljs.highlight(source, {language: language, ignoreIllegals: true}).value;
        })
        """)
        let value = function?.call(withArguments: [request.source, request.language])
        guard context.exception == nil, let value, value.isString,
              let result = value.toString(), result.utf8.count <= 1024 * 1024 else { exit(1) }
        try FileHandle.standardOutput.write(contentsOf: Data(result.utf8))
    }
}
