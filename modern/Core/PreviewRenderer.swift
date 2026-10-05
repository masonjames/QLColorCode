// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

struct PreviewRenderer {
    // No source evaluation, language auto-detection, or runtime downloads.
    // Larger inputs remain useful as plain text without expensive grammar processing.
    static let highlightByteLimit = 32 * 1024
    let highlighter: (String, String, () -> Bool) -> String?

    init() { highlighter = IsolatedHighlighter().highlight }
    init(highlighter: @escaping (String, String, () -> Bool) -> String?) { self.highlighter = highlighter }

    static func preview(_ url: URL) async throws -> String {
        let worker = Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            let html = PreviewRenderer().render(try SourceDocument.read(url))
            try Task.checkCancellation()
            return html
        }
        return try await withTaskCancellationHandler { try await worker.value } onCancel: { worker.cancel() }
    }

    static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;", options: .literal)
            .replacingOccurrences(of: "<", with: "&lt;", options: .literal)
            .replacingOccurrences(of: ">", with: "&gt;", options: .literal)
            .replacingOccurrences(of: "\"", with: "&quot;", options: .literal)
            .replacingOccurrences(of: "'", with: "&#39;", options: .literal)
    }

    func render(_ document: SourceDocument) -> String {
        let lineCount = document.lineCount
        let highlighted = highlight(document).flatMap { Self.numberedLines($0, count: lineCount) }
        let plain = Self.escape(document.text)
        let lines = highlighted ?? Self.numberedLines(plain, count: lineCount) ?? plain
        let language = highlighted == nil ? "Plain text" : document.languageName
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
        main { padding:16px 20px 24px 0; }
        pre { margin:0; tab-size:4; font:13px/1.6 ui-monospace,SFMono-Regular,Menlo,monospace;
          white-space:pre-wrap; overflow-wrap:anywhere; }
        .source { --gutter:calc(\(String(lineCount).count)ch + 32px); padding-left:var(--gutter); }
        .line { display:block; position:relative; min-height:1.6em; padding-left:16px;
          border-left:1px solid var(--rule); }
        .line::before { content:attr(data-line); content:attr(data-line) / "";
          position:absolute; right:100%; top:0;
          box-sizing:border-box; width:var(--gutter); padding-right:16px; color:var(--muted); text-align:right;
          user-select:none; -webkit-user-select:none; }
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
        <main><pre class="source"><code>\(lines)</code></pre></main>
        </body></html>
        """
    }

    // Highlight.js can span several source lines with one token. Balance those
    // spans inside each row so wrapping keeps the gutter aligned without losing
    // multiline syntax. Literal newlines remain in the selectable source text.
    private static func numberedLines(_ html: String, count: Int) -> String? {
        guard count > 0 else { return "" }
        let tokens = html.ranges(of: /<[^>]*>|<|\n/.matchingSemantics(.unicodeScalar))
        var openSpans: [String] = []
        var result = ""
        var line = ""
        var number = 1
        var cursor = html.startIndex
        for range in tokens {
            line += html[cursor..<range.lowerBound]
            let token = String(html[range])
            if token == "\n" {
                line += String(repeating: "</span>", count: openSpans.count) + "\n"
                result += "<span class=\"line\" data-line=\"\(number)\">\(line)</span>"
                number += 1
                line = openSpans.joined()
            } else {
                line += token
                if token == "</span>" {
                    guard openSpans.popLast() != nil else { return nil }
                } else {
                    guard token.wholeMatch(of: /<span class="[a-zA-Z0-9 _-]+">/.matchingSemantics(.unicodeScalar)) != nil else { return nil }
                    openSpans.append(token)
                }
            }
            cursor = range.upperBound
        }
        if number <= count {
            line += html[cursor...]
            result += "<span class=\"line\" data-line=\"\(number)\">\(line)</span>"
        }
        return openSpans.isEmpty ? result : nil
    }

    private func highlight(_ document: SourceDocument) -> String? {
        guard let language = document.language,
              document.text.utf8.count <= Self.highlightByteLimit,
              !document.text.split(separator: "\n").contains(where: { $0.utf8.count > 2000 }) else { return nil }
        return highlighter(document.text, language, { Task.isCancelled })
    }
}
