// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Darwin

enum PreviewError: String, LocalizedError {
    case notRegularFile = "Choose a regular source file."
    case unreadable = "This file could not be read."
    case unsupportedEncoding = "This preview supports UTF-8 and UTF-16 text."
    case binary = "This file contains binary data and cannot be previewed as source code."

    var errorDescription: String? { rawValue }
}

struct SourceDocument {
    static let byteLimit = 256 * 1024
    static let lineLimit = 6000

    let name: String
    let text: String
    let language: String?
    let truncated: Bool

    var lineCount: Int {
        guard !text.isEmpty else { return 0 }
        return text.filter { $0 == "\n" }.count + (text.hasSuffix("\n") ? 0 : 1)
    }

    static func read(_ url: URL) throws -> SourceDocument {
        guard url.isFileURL else { throw PreviewError.notRegularFile }
        // O_NONBLOCK prevents a FIFO from hanging before fstat can reject it.
        let descriptor = url.withUnsafeFileSystemRepresentation { path in
            path.map { Darwin.open($0, O_RDONLY | O_NONBLOCK | O_CLOEXEC) } ?? -1
        }
        guard descriptor >= 0 else { throw PreviewError.unreadable }
        defer { Darwin.close(descriptor) }
        var info = stat()
        guard fstat(descriptor, &info) == 0 else { throw PreviewError.unreadable }
        guard info.st_mode & S_IFMT == S_IFREG else { throw PreviewError.notRegularFile }

        var bytes = [UInt8](repeating: 0, count: byteLimit + 1)
        var count = 0
        while count < bytes.count {
            let amount = bytes.withUnsafeMutableBytes { buffer in
                Darwin.read(descriptor, buffer.baseAddress!.advanced(by: count), buffer.count - count)
            }
            if amount == 0 { break }
            if amount < 0 {
                if errno == EINTR { continue }
                throw PreviewError.unreadable
            }
            count += amount
        }
        let byteTruncated = count > byteLimit
        let data = Data(bytes.prefix(min(count, byteLimit)))
        let decoded = try decode(data, truncated: byteTruncated)
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        guard !decoded.unicodeScalars.contains(where: {
            ($0.value < 32 && ![9, 10, 11, 12].contains($0.value)) || $0.value == 127
        }) else { throw PreviewError.binary }

        let lines = decoded.split(separator: "\n", omittingEmptySubsequences: false)
        let lineCount = lines.count - (decoded.hasSuffix("\n") ? 1 : 0)
        let lineTruncated = lineCount > lineLimit
        return SourceDocument(
            name: url.lastPathComponent,
            text: lineTruncated ? lines.prefix(lineLimit).joined(separator: "\n") + "\n" : decoded,
            language: language(for: url.lastPathComponent),
            truncated: byteTruncated || lineTruncated
        )
    }

    private static func decode(_ data: Data, truncated: Bool) throws -> String {
        let bytes = [UInt8](data)
        // UTF-32 is deliberately not interpreted as UTF-16.
        if bytes.starts(with: [0xFF, 0xFE, 0, 0]) || bytes.starts(with: [0, 0, 0xFE, 0xFF]) {
            throw PreviewError.unsupportedEncoding
        }
        let encoding: String.Encoding
        let prefixLength: Int
        if bytes.starts(with: [0xFF, 0xFE]) {
            encoding = .utf16LittleEndian; prefixLength = 2
        } else if bytes.starts(with: [0xFE, 0xFF]) {
            encoding = .utf16BigEndian; prefixLength = 2
        } else {
            encoding = .utf8
            prefixLength = bytes.starts(with: [0xEF, 0xBB, 0xBF]) ? 3 : 0
        }
        let body = Data(bytes.dropFirst(prefixLength))
        if let text = String(data: body, encoding: encoding) { return text }
        // Only a valid but incomplete final code point may be discarded.
        if truncated, encoding == .utf8 {
            for trim in 1...min(3, max(body.count, 1)) {
                let tail = Array(body.suffix(trim))
                guard let lead = tail.first else { continue }
                let expected = (0xC2...0xDF).contains(lead) ? 2 : (0xE0...0xEF).contains(lead) ? 3 : (0xF0...0xF4).contains(lead) ? 4 : 0
                guard expected > tail.count, tail.dropFirst().allSatisfy({ (0x80...0xBF).contains($0) }) else { continue }
                if tail.count > 1 {
                    if lead == 0xE0 && tail[1] < 0xA0 { continue }
                    if lead == 0xED && tail[1] > 0x9F { continue }
                    if lead == 0xF0 && tail[1] < 0x90 { continue }
                    if lead == 0xF4 && tail[1] > 0x8F { continue }
                }
                if let text = String(data: body.dropLast(trim), encoding: .utf8) { return text }
            }
        } else if truncated, body.count >= 2, body.count.isMultiple(of: 2) {
            let tail = Array(body.suffix(2))
            let unit = encoding == .utf16LittleEndian ? UInt16(tail[0]) | UInt16(tail[1]) << 8 : UInt16(tail[0]) << 8 | UInt16(tail[1])
            if (0xD800...0xDBFF).contains(unit), let text = String(data: body.dropLast(2), encoding: encoding) { return text }
        }
        throw PreviewError.unsupportedEncoding
    }

    static func language(for name: String) -> String? {
        let lower = name.lowercased()
        if ["makefile", "gnumakefile"].contains(lower) { return "makefile" }
        if [".bashrc", ".zshrc", ".bash_profile", ".zprofile"].contains(lower) { return "bash" }
        let ext = (lower as NSString).pathExtension
        return [
            "c": "c", "h": "c", "cpp": "cpp", "cc": "cpp", "cxx": "cpp", "hpp": "cpp",
            "m": "objectivec", "mm": "objectivec", "swift": "swift",
            "js": "javascript", "mjs": "javascript", "cjs": "javascript", "jsx": "javascript",
            "ts": "typescript", "tsx": "typescript", "mts": "typescript", "cts": "typescript",
            "py": "python", "pyw": "python", "rb": "ruby", "rs": "rust", "go": "go",
            "java": "java", "kt": "kotlin", "kts": "kotlin", "cs": "csharp",
            "sh": "bash", "bash": "bash", "zsh": "bash", "pl": "perl", "pm": "perl",
            "lua": "lua", "php": "php", "r": "r", "sql": "sql",
            "json": "json", "yaml": "yaml", "yml": "yaml", "toml": "ini", "ini": "ini",
            "xml": "xml", "xsl": "xml", "xsd": "xml", "plist": "xml", "html": "xml",
            "css": "css", "scss": "scss", "less": "less", "md": "markdown",
            "markdown": "markdown", "diff": "diff", "patch": "diff", "mk": "makefile",
            "graphql": "graphql", "gql": "graphql"
        ][ext]
    }
}
