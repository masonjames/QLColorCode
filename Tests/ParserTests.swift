// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Darwin

@main
struct ParserTests {
    static func main() throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("qlcolorcode-parser-\(UUID())")
        defer { try? fm.removeItem(at: root) }
        try fm.copyItem(at: URL(fileURLWithPath: "build/tests/Parser"), to: root)
        let helper = root.appendingPathComponent("Contents/Helpers/QLColorCodeHighlight")
        let resource = root.appendingPathComponent("Contents/Resources/highlight.min.js")
        let library = try Data(contentsOf: resource)
        let client = IsolatedHighlighter(executable: helper)
        let clock = ContinuousClock()
        var checks = 0
        func expect(_ condition: Bool, _ label: String) throws {
            guard condition else { throw NSError(domain: "ParserTests", code: 1, userInfo: [NSLocalizedDescriptionKey: label]) }
            checks += 1
        }
        func run(_ parser: IsolatedHighlighter, _ input: String = "let answer = 42") -> String? {
            parser.highlight(input, language: "swift", isCancelled: { false })
        }
        try expect(run(client)?.contains("hljs-keyword") == true, "Actual helper highlights")
        try "while (true) {}".write(to: resource, atomically: true, encoding: .utf8)
        let start = clock.now
        try expect(run(client) == nil, "Hung grammar falls back")
        try expect(start.duration(to: clock.now) < .seconds(1.5), "Parent deadline")
        let cancelled = clock.now
        try expect(client.highlight("let x = 1", language: "swift", isCancelled: {
            cancelled.duration(to: clock.now) > .milliseconds(100)
        }) == nil, "In-flight cancellation")
        try expect(cancelled.duration(to: clock.now) < .milliseconds(500), "Cancellation is prompt")
        try "throw new Error('test');".write(to: resource, atomically: true, encoding: .utf8)
        try expect(run(client) == nil, "Parser error falls back")
        try library.write(to: resource)
        try expect(run(client)?.contains("hljs-keyword") == true, "Next preview recovers")
        try expect(run(IsolatedHighlighter(executable: root.appendingPathComponent("missing"))) == nil, "Missing executable falls back")
        let probe = IsolatedHighlighter(executable: URL(fileURLWithPath: "build/tests/parser-probe"))
        try expect(run(probe, "crash") == nil, "Partial output then crash rejected")
        try expect(run(probe, "oversize") == nil, "Unbounded output rejected")
        let fd = open("/dev/null", O_RDONLY)
        guard fd >= 0, dup2(fd, 80) == 80 else { throw PreviewError.unreadable }
        defer { close(fd); close(80); unsetenv("QLCOLORCODE_TEST_PARENT") }
        setenv("QLCOLORCODE_TEST_PARENT", "must-not-inherit", 1)
        try expect(run(probe, "descriptors") == "clean", "Only stdin/stdout/stderr and no environment inherited")
        let previous = signal(SIGCHLD, SIG_IGN)
        defer { signal(SIGCHLD, previous) }
        try expect(run(client) == nil, "A host that auto-reaps children falls back safely")
        print("PASS: \(checks) parser boundary checks; timeout, cancellation, crash, output cap, descriptors and recovery")
    }
}
