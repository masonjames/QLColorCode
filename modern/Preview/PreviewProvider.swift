// SPDX-License-Identifier: GPL-3.0-or-later
import Cocoa
import Quartz
import UniformTypeIdentifiers

final class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        let url = request.fileURL
        let resourceBundle = Bundle(for: PreviewProvider.self)
        let html = try await PreviewRenderer.preview(url, bundle: resourceBundle)
        return QLPreviewReply(dataOfContentType: .html, contentSize: CGSize(width: 900, height: 700)) { reply in
            reply.stringEncoding = .utf8
            return Data(html.utf8)
        }
    }
}
