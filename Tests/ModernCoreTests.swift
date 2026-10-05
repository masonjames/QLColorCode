// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Darwin
import UniformTypeIdentifiers

@main
struct ModernCoreTests {
    static func main() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("qlcolorcode-tests-\(UUID())")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let renderer = PreviewRenderer(helper: URL(fileURLWithPath: "build/tests/Parser/Contents/Helpers/QLColorCodeHighlight"))
        var checks = 0
        func expect(_ condition: @autoclosure () throws -> Bool, _ label: String) throws {
            guard try condition() else { throw NSError(domain: "ModernCoreTests", code: 1, userInfo: [NSLocalizedDescriptionKey: label]) }
            checks += 1
        }
        func write(_ name: String, _ data: Data) throws -> URL {
            let file = root.appendingPathComponent(name)
            try data.write(to: file)
            return file
        }
        func rejected(_ url: URL, _ reason: PreviewError) throws {
            do {
                _ = try SourceDocument.read(url)
                throw NSError(domain: "ModernCoreTests", code: 2, userInfo: [NSLocalizedDescriptionKey: "Expected rejection: \(reason)"])
            } catch let error as PreviewError { try expect(error == reason, "Unexpected rejection") }
        }

        let swift = try write("quote ' $ % < &.swift", Data("let greeting = \"Hello 👋\"\n".utf8))
        let source = try SourceDocument.read(swift)
        try expect(source.text == "let greeting = \"Hello 👋\"\n", "UTF-8 preservation")
        let html = renderer.render(source)
        try expect(html.contains("<span class=\"hljs-keyword\">"), "Swift highlighting")
        try expect(html.contains("quote &#39; $ % &lt; &amp;.swift"), "Filename escaped")
        try expect(html.contains("prefers-color-scheme:dark"), "Automatic dark appearance")
        try expect(!html.contains("<script"), "No scripts in preview")

        let hostile = "</code><script>throw new Error('executed')</script><img src=https://example.invalid/x>"
        for name in ["hostile.txt", "hostile.js", "hostile.html"] {
            let file = try write(name, Data(hostile.utf8))
            let preview = renderer.render(try SourceDocument.read(file))
            try expect(!preview.contains("<script>"), "Source cannot inject a script")
            try expect(!preview.contains("<img "), "Source cannot inject a resource")
        }
        let bom = try write("bom.py", Data([0xEF, 0xBB, 0xBF]) + Data("print('ok')".utf8))
        try expect(try SourceDocument.read(bom).text == "print('ok')", "UTF-8 BOM")
        for (encoding, prefix) in [(String.Encoding.utf16LittleEndian, [UInt8](arrayLiteral: 0xFF, 0xFE)), (.utf16BigEndian, [0xFE, 0xFF])] {
            let file = try write("utf16.py", Data(prefix) + "print('👋')".data(using: encoding)!)
            try expect(try SourceDocument.read(file).text == "print('👋')", "UTF-16 BOM")
            let boundaryText = String(repeating: "a", count: (SourceDocument.byteLimit - 4) / 2) + "👋tail"
            let boundaryFile = try write("utf16-boundary.py", Data(prefix) + boundaryText.data(using: encoding)!)
            let bounded = try SourceDocument.read(boundaryFile)
            try expect(bounded.truncated && bounded.text.allSatisfy({ $0 == "a" }), "UTF-16 surrogate at byte limit")
        }
        let invalid = try write("invalid.py", Data([0xFF, 0x41]))
        try rejected(invalid, .unsupportedEncoding)
        let binary = try write("binary.ts", Data([0, 1, 2, 3]))
        try rejected(binary, .binary)
        let empty = try write("empty.rs", Data())
        try expect(try SourceDocument.read(empty).text.isEmpty, "Empty file")
        try expect(try SourceDocument.read(empty).lineCount == 0, "Empty line count")
        try expect(renderer.render(try SourceDocument.read(empty)).contains("<code></code>"), "Empty preview")
        let crlf = try write("crlf.js", Data("a\r\nb\rc".utf8))
        try expect(try SourceDocument.read(crlf).text == "a\nb\nc", "Line ending normalization")
        for (input, finalLine) in [("a\r\nb", 2), ("a\r\nb\r\n", 2), ("a\r\nb\nc", 3)] {
            let file = try write("line-endings.txt", Data(input.utf8))
            let document = try SourceDocument.read(file)
            let preview = renderer.render(document)
            try expect(document.lineCount == finalLine && preview.contains("data-line=\"\(finalLine)\">\(finalLine == 2 ? "b" : "c")"), "CRLF/mixed endings keep the final logical line")
        }
        let formFeed = try write("formfeed.c", Data("/* page */\u{0C}int main() {}\n".utf8))
        try expect(try SourceDocument.read(formFeed).text.contains("\u{0C}"), "Form feed is source whitespace")
        let exactLines = try write("exact.go", Data(String(repeating: "x\n", count: SourceDocument.lineLimit).utf8))
        let exactDocument = try SourceDocument.read(exactLines)
        try expect(!exactDocument.truncated && exactDocument.lineCount == SourceDocument.lineLimit, "Exactly 6000 terminated lines")
        try expect(source.lineCount == 1, "Trailing newline does not add a source line")

        let large = try write("large.py", Data(repeating: 65, count: SourceDocument.byteLimit + 10))
        let largeDocument = try SourceDocument.read(large)
        try expect(largeDocument.truncated && largeDocument.text.utf8.count == SourceDocument.byteLimit, "Bounded read")
        let largeHTML = renderer.render(largeDocument)
        try expect(largeHTML.contains("Showing the beginning"), "Visible truncation")
        try expect(largeHTML.contains("Plain text"), "Large input avoids grammar processing")
        for boundary in 1...3 {
            let content = String(repeating: "a", count: SourceDocument.byteLimit - boundary) + "👋tail"
            let file = try write("split.swift", Data(content.utf8))
            let document = try SourceDocument.read(file)
            try expect(document.truncated && !document.text.contains("�"), "Truncated UTF-8 code point")
        }
        let invalidBoundary = try write("bad-boundary.py", Data(repeating: 65, count: SourceDocument.byteLimit - 1) + Data([0xFF, 65, 65]))
        try rejected(invalidBoundary, .unsupportedEncoding)
        let manyLines = try write("lines.go", Data(String(repeating: "x\n", count: 7000).utf8))
        try expect(try SourceDocument.read(manyLines).truncated, "Line count cap")
        let link = root.appendingPathComponent("linked.swift")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: swift)
        try expect(try SourceDocument.read(link).text == source.text, "Regular file symlink")
        try rejected(root, .notRegularFile)
        let fifo = root.appendingPathComponent("pipe.py")
        guard mkfifo(fifo.path, 0o600) == 0 else { throw PreviewError.unreadable }
        try rejected(fifo, .notRegularFile)
        try rejected(root.appendingPathComponent("missing.py"), .unreadable)

        let executable = try write("executable.h", Data("#!/bin/sh\ntouch '\(root.path)/executed'\n".utf8))
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: executable.path)
        _ = renderer.render(try SourceDocument.read(executable))
        try expect(!FileManager.default.fileExists(atPath: root.appendingPathComponent("executed").path), "Source never executes")
        let plain = PreviewRenderer(helper: nil).render(source)
        try expect(plain.contains("Plain text") && plain.contains("Hello 👋"), "Missing parser falls back")
        try expect(PreviewRenderer.escape("<\u{0338}script>&\u{0338}") == "&lt;\u{0338}script&gt;&amp;\u{0338}", "Literal escaping beside combining marks")
        let nestedMarkup = "<span class=\"hljs-title function_\">first<span class=\"hljs-string\">\nsecond</span></span>"
        let nestedDocument = SourceDocument(name: "nested.js", text: "first\nsecond", language: "javascript", truncated: false)
        let nestedHTML = PreviewRenderer { _, _, _ in nestedMarkup }.render(nestedDocument)
        try expect(nestedHTML.contains("<span class=\"line\" data-line=\"1\"><span class=\"hljs-title function_\">first<span class=\"hljs-string\"></span></span>\n</span><span class=\"line\" data-line=\"2\"><span class=\"hljs-title function_\"><span class=\"hljs-string\">second</span></span></span>"), "Nested multiline and multi-class tokens remain balanced per line")
        for markup in ["</span>", "<span class=\"hljs-comment\">unfinished", "<img src=x>", "<span onclick=\"alert(1)\">bad</span>"] {
            let preview = PreviewRenderer { _, _, _ in markup }.render(source)
            try expect(preview.contains("Plain text") && preview.contains("Hello 👋") && !preview.contains("<img "), "Malformed markup falls back to literal source")
        }
        for (name, label) in [("code.cpp", "C++"), ("code.mm", "Objective-C++"), ("app.cs", "C#"), ("settings.toml", "TOML"), ("settings.ini", "INI"), ("view.tsx", "TypeScript JSX")] {
            let document = SourceDocument(name: name, text: "", language: SourceDocument.language(for: name), truncated: false)
            try expect(document.languageName == label, "Readable language name for \(name)")
        }
        try expect(SourceDocument.language(for: "Main.TSX") == "typescript", "TSX mapping")
        try expect(SourceDocument.language(for: "Makefile") == "makefile", "Extensionless build file")
        try expect(SourceDocument.language(for: "unrecognized.bin") == nil, "Unknown extension")

        let fixtures = [
            ("ts", "export const answer: number = 42;"), ("tsx", "const view = <div>Hello</div>;"),
            ("py", "def greet(name):\n    return f'Hello {name}'"), ("rs", "fn main() { println!(\"hello\"); }"),
            ("go", "package main\nfunc main() {}"), ("yaml", "enabled: true\nname: preview"),
            ("toml", "[preview]\nenabled = true"), ("cpp", "/* multiline\ncomment */\nint main() {}"),
            ("json", "{\"enabled\": true}"), ("sh", "#!/bin/sh\necho 'hello'"),
            ("md", "# Title\n\n**hello**"), ("php", "<?php echo \"hello\";"),
            ("swift", String(repeating: "let x = 42\n", count: 1500)),
            ("js", String(repeating: "/*/" + String(repeating: "/", count: 900) + "\n", count: 30))
        ]
        let start = Date()
        for (ext, code) in fixtures {
            let file = try write("fixture.\(ext)", Data(code.utf8))
            let preview = renderer.render(try SourceDocument.read(file))
            try expect(preview.contains("<span class=\"hljs-"), "Grammar available: \(ext)")
        }
        let elapsed = Date().timeIntervalSince(start)
        try expect(elapsed < 10, "Fixture corpus timing exceeded 10 seconds")
        print("PASS: \(checks) assertions; \(fixtures.count) rendering fixtures in \(String(format: "%.3f", elapsed))s")
        for ext in ["swift", "py", "js", "jsx", "ts", "tsx", "rs", "go", "yaml", "toml", "kt", "css", "json", "md", "sql", "php", "lua"] {
            print("Host UTI .\(ext): \(UTType(filenameExtension: ext)?.identifier ?? "unknown")")
        }
    }
}
