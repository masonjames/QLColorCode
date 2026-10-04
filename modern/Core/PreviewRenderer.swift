// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import JavaScriptCore

struct PreviewRenderer {
    // No source evaluation, subprocesses, language auto-detection, or runtime downloads.
    // Larger inputs remain useful as plain text without expensive grammar processing.
    static let highlightByteLimit = 32 * 1024
    let library: String?

    init(bundle: Bundle) {
        library = bundle.url(forResource: "highlight.min", withExtension: "js")
            .flatMap { try? String(contentsOf: $0, encoding: .utf8) }
    }

    init(library: String?) { self.library = library }

    static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    func render(_ document: SourceDocument) -> String {
        let highlighted = highlight(document)
        let code = highlighted ?? Self.escape(document.text)
        let lineCount = document.lineCount
        let numbers = lineCount == 0 ? "" : (1...lineCount).map(String.init).joined(separator: "\n")
        let language = highlighted == nil ? "Plain text" : document.language ?? "Plain text"
        let notice = document.truncated ? " · Showing the beginning of this file" : ""
        let plainNotice = document.language != nil && highlighted == nil ? " · Syntax highlighting unavailable for this preview" : ""
        let lineLabel = lineCount == 1 ? "line" : "lines"
        return """
        <!doctype html>
        <html lang="en"><head><meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'">
        <meta name="color-scheme" content="light dark">
        <title>\(Self.escape(document.name))</title>
        <style>
        :root { color-scheme:light dark; --bg:#fff; --fg:#24292f; --muted:#57606a;
          --rule:#d8dee4; --keyword:#cf222e; --string:#0a3069; --number:#0550ae; --title:#8250df; }
        @media(prefers-color-scheme:dark) { :root { --bg:#0d1117; --fg:#e6edf3; --muted:#919ba5;
          --rule:#30363d; --keyword:#ff7b72; --string:#a5d6ff; --number:#79c0ff; --title:#d2a8ff; } }
        * { box-sizing:border-box; }
        body { margin:0; background:var(--bg); color:var(--fg); }
        header { padding:12px 20px; border-bottom:1px solid var(--rule);
          font:12px -apple-system,BlinkMacSystemFont,sans-serif; color:var(--muted); overflow-wrap:anywhere; }
        main { display:flex; padding:16px 20px 24px 0; overflow:auto; }
        pre { margin:0; tab-size:4; font:13px/1.6 ui-monospace,SFMono-Regular,Menlo,monospace; }
        .numbers { flex:none; padding:0 16px; color:var(--muted); text-align:right;
          position:sticky; left:0; background:var(--bg);
          border-right:1px solid var(--rule); user-select:none; -webkit-user-select:none; }
        .source { padding-left:16px; }
        code { font:inherit; }
        .hljs-comment,.hljs-quote { color:var(--muted); font-style:italic; }
        .hljs-keyword,.hljs-selector-tag,.hljs-literal { color:var(--keyword); }
        .hljs-string,.hljs-regexp,.hljs-addition { color:var(--string); }
        .hljs-number,.hljs-built_in,.hljs-attr,.hljs-variable,.hljs-type { color:var(--number); }
        .hljs-title,.hljs-section,.hljs-name,.hljs-selector-class { color:var(--title); }
        .hljs-meta,.hljs-symbol { color:var(--number); }
        .hljs-deletion { color:var(--keyword); }
        .hljs-emphasis { font-style:italic; } .hljs-strong { font-weight:600; }
        </style></head><body>
        <header>QLColorCode · \(Self.escape(language)) · \(lineCount) \(lineLabel)\(notice)\(plainNotice)</header>
        <main><pre class="numbers" aria-hidden="true">\(numbers)</pre><pre class="source"><code>\(code)</code></pre></main>
        </body></html>
        """
    }

    private func highlight(_ document: SourceDocument) -> String? {
        guard let language = document.language, let library,
              document.text.utf8.count <= Self.highlightByteLimit,
              !document.text.split(separator: "\n").contains(where: { $0.utf8.count > 2000 }),
              let context = JSContext() else { return nil }
        context.evaluateScript(library)
        guard context.exception == nil else { return nil }
        let function = context.evaluateScript("""
        (function(source, language) {
          if (!hljs.getLanguage(language)) return null;
          return hljs.highlight(source, {language: language, ignoreIllegals: true}).value;
        })
        """)
        let result = function?.call(withArguments: [document.text, language])
        guard context.exception == nil, let result, result.isString else { return nil }
        return result.toString()
    }
}
