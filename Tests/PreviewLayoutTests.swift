// SPDX-License-Identifier: GPL-3.0-or-later
import AppKit
import WebKit

/// Exercises the actual HTML in WebKit, including its text-selection behavior.
@MainActor
private final class LayoutTests: NSObject, WKNavigationDelegate {
    private let web = WKWebView(frame: NSRect(x: 0, y: 0, width: 320, height: 600))
    private let renderer: PreviewRenderer
    private let fixtures: [(String, String)] = [
        ("empty.swift", ""), ("blank.swift", "\n\n"),
        ("comment.cpp", "/* A long comment " + String(repeating: "with words ", count: 60) + "\n\tstill a comment\n\nend */\nint answer = 42;\n"),
        ("unfinished.cpp", "/* first\nsecond\n"),
        ("string.py", "message = \"\"\"first\n\tsecond\n\nlast\"\"\"\n"),
        ("markup.tsx", "const view = <div title=\"hello\">\n  <span>世界 👋 &amp; hello</span>\n</div>;"),
        ("keycap.js", "const keycap = 1️⃣;\n"),
        ("literal.txt", "\t</code><script>alert('hello')</script> & \"quoted\"\n\n  final line"),
        ("long.txt", String(repeating: "abcdef👋", count: 600) + "\nend\n"),
        ("spaces.txt", "    leading and trailing    \n\t\tindented\n"),
        ("settings.toml", "[preview]\nenabled = true\n"),
        ("many.txt", String(repeating: "\tline\n", count: SourceDocument.lineLimit)),
        ("truncated.py", String(repeating: "x", count: SourceDocument.byteLimit))
    ]
    private var index = 0
    private var checks = 0

    init(library: String) {
        renderer = PreviewRenderer(library: library)
        super.init()
        web.navigationDelegate = self
    }

    func next() {
        guard index < fixtures.count * 4 else {
            print("PASS: \(checks) WebKit layout/selection assertions; \(fixtures.count) fixtures at 320/960px in light/dark appearance")
            NSApplication.shared.terminate(nil)
            return
        }
        let variant = index / fixtures.count
        web.frame.size.width = variant.isMultiple(of: 2) ? 320 : 960
        web.appearance = NSAppearance(named: variant < 2 ? .aqua : .darkAqua)
        let (name, text) = fixtures[index % fixtures.count]
        let document = SourceDocument(name: name, text: text, language: SourceDocument.language(for: name), truncated: name == "truncated.py")
        web.loadHTMLString(renderer.render(document), baseURL: nil)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let (name, expected) = fixtures[index % fixtures.count]
        web.evaluateJavaScript("""
        (() => {
          const code = document.querySelector('code');
          const range = document.createRange(); range.selectNodeContents(code);
          const selection = getSelection(); selection.removeAllRanges(); selection.addRange(range);
          const lines = [...code.querySelectorAll('.line')];
          const rectangles = lines.map(line => line.getBoundingClientRect());
          const allSelected = selection.toString();
          const start = Math.min(5, code.textContent.length);
          const end = Math.max(start, Math.min(code.textContent.length, code.textContent.indexOf('\\n') + 7));
          const walker = document.createTreeWalker(code, NodeFilter.SHOW_TEXT);
          const partial = document.createRange(); let offset = 0;
          for (let node = walker.nextNode(); node; node = walker.nextNode()) {
            if (offset <= start && start <= offset + node.length) partial.setStart(node, start - offset);
            if (offset <= end && end <= offset + node.length) partial.setEnd(node, end - offset);
            offset += node.length;
          }
          selection.removeAllRanges(); selection.addRange(partial);
          return {
            text: code.textContent, range: range.toString(), selection: allSelected,
            partial: selection.toString(), expectedPartial: code.textContent.slice(start, end),
            count: lines.length, overflow: document.documentElement.scrollWidth > innerWidth,
            aligned: lines.every((line, i) => line.dataset.line === String(i + 1)
              && rectangles[i].left + 1 >= parseFloat(getComputedStyle(code.parentElement).paddingLeft)
              && (i === 0 || Math.abs(rectangles[i].top - rectangles[i-1].bottom) < 1)),
            wrapped: rectangles.some(rect => rect.height > 25),
            continuedComment: !!lines[1]?.querySelector('.hljs-comment'),
            tokens: !!code.querySelector('.line [class^="hljs-"]'),
            background: getComputedStyle(document.body).backgroundColor,
            label: document.querySelector('header').textContent
          };
        })()
        """) { [self] result, error in
            guard error == nil, let values = result as? [String: Any] else {
                fail("WebKit evaluation: \(error?.localizedDescription ?? "missing result")")
            }
            let document = SourceDocument(name: name, text: expected, language: nil, truncated: false)
            check(values["text"] as? String == expected, "DOM preserves source", name)
            check(values["range"] as? String == expected, "Range preserves source", name)
            check(values["selection"] as? String == expected, "Selection preserves source and excludes gutter", name)
            check(values["partial"] as? String == values["expectedPartial"] as? String, "Partial selection preserves source", name)
            check(values["count"] as? Int == document.lineCount, "Logical line count", name)
            check(values["overflow"] as? Bool == false, "No horizontal overflow", name)
            check(values["aligned"] as? Bool == true, "Gutter follows logical lines", name)
            let expectedBackground = index / fixtures.count < 2 ? "rgb(255, 255, 255)" : "rgb(13, 17, 23)"
            check(values["background"] as? String == expectedBackground, "Requested appearance renders", name)
            if SourceDocument.language(for: name) != nil && name != "truncated.py" {
                check((values["label"] as? String)?.contains("Syntax highlighting unavailable") == false, "No silent highlighting fallback", name)
            }
            if ["string.py", "markup.tsx", "unfinished.cpp", "keycap.js"].contains(name) {
                check(values["tokens"] as? Bool == true, "Highlight tokens survive line formatting", name)
            }
            if name == "comment.cpp" {
                check(values["continuedComment"] as? Bool == true, "Multiline comment highlighting", name)
                check(values["wrapped"] as? Bool == true, "Long comments wrap", name)
            }
            if name == "long.txt" { check(values["wrapped"] as? Bool == true, "Unbroken tokens wrap", name) }
            if name == "settings.toml" { check((values["label"] as? String)?.contains("TOML") == true, "TOML display name", name) }
            if name == "truncated.py" { check((values["label"] as? String)?.contains("Showing the beginning") == true, "Truncation notice", name) }
            index += 1
            next()
        }
    }

    private func check(_ condition: Bool, _ label: String, _ fixture: String) {
        guard condition else { fail("\(fixture), case \(index): \(label)") }
        checks += 1
    }

    private func fail(_ message: String) -> Never {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

@main
struct PreviewLayoutTests {
    @MainActor static func main() throws {
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        let tests = LayoutTests(library: try String(contentsOfFile: "modern/Resources/highlight.min.js", encoding: .utf8))
        tests.next()
        app.run()
    }
}
