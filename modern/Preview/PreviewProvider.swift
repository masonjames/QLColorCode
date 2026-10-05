// SPDX-License-Identifier: GPL-3.0-or-later
import Cocoa
import Quartz
import UniformTypeIdentifiers

final class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        let url = request.fileURL
        let resourceBundle = Bundle(for: PreviewProvider.self)
        // Quick Look invokes the data block off the request path for expensive work.
        return QLPreviewReply(dataOfContentType: .html, contentSize: CGSize(width: 900, height: 700)) { reply in
            let document = try SourceDocument.read(url)
            reply.stringEncoding = .utf8
            return Data(PreviewRenderer(bundle: resourceBundle).render(document).utf8)
        }
    }
}
