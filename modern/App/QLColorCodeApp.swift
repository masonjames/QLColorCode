// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI
import WebKit
import UniformTypeIdentifiers

@main
struct QLColorCodeApp: App {
    var body: some Scene {
        WindowGroup("QLColorCode") {
            ContentView().frame(minWidth: 740, minHeight: 520)
        }
        .defaultSize(width: 920, height: 680)
    }
}

private struct ContentView: View {
    @State private var html: String?
    @State private var fileName: String?
    @State private var error: String?
    @State private var choosingFile = false
    @State private var loading = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 28)).foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 3) {
                    Text("QLColorCode").font(.title2.weight(.semibold))
                    Text("A closer look at your code.").foregroundStyle(.secondary)
                }
                Spacer()
                Button("Choose a file…", systemImage: "doc") { choosingFile = true }
                    .disabled(loading)
                    .keyboardShortcut("o")
            }
            .padding(22)
            Divider()
            if loading {
                ProgressView("Preparing preview…").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let html {
                PreviewWebView(html: html)
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Source previews, right in Finder.").font(.title.weight(.semibold))
                    Text("Select a source file in Finder and press Space to see its code with syntax highlighting.")
                        .font(.body).foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Keep QLColorCode in Applications.", systemImage: "1.circle")
                        Label("Enable its Quick Look extension in System Settings.", systemImage: "2.circle")
                        Label("Try a Swift, Python, JavaScript, or other source file.", systemImage: "3.circle")
                    }
                    Text("System Settings → General → Login Items & Extensions → Quick Look")
                        .font(.callout).foregroundStyle(.secondary).textSelection(.enabled)
                    Button("Open System Settings") { NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app")) }
                    Text("Choose a file above to test rendering here. Finder previews also require the extension to be enabled.")
                        .font(.callout).foregroundStyle(.secondary)
                }
                .frame(maxWidth: 580, alignment: .leading)
                .padding(30).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Divider()
            HStack {
                Text(fileName ?? "Offline by design. Your files stay on your Mac.")
                    .lineLimit(1).truncationMode(.middle)
                Spacer()
                Text("Development preview").foregroundStyle(.secondary)
            }
            .font(.caption).padding(.horizontal, 20).padding(.vertical, 10)
        }
        .fileImporter(isPresented: $choosingFile, allowedContentTypes: [.item]) { result in
            switch result {
            case .success(let url): preview(url)
            case .failure(let failure): error = failure.localizedDescription
            }
        }
        .alert("Unable to preview this file", isPresented: Binding(
            get: { error != nil }, set: { if !$0 { error = nil } }
        )) { Button("OK") { error = nil } } message: { Text(error ?? "") }
    }

    private func preview(_ url: URL) {
        loading = true
        Task {
            do {
                let rendered = try await Task.detached(priority: .userInitiated) {
                    let access = url.startAccessingSecurityScopedResource()
                    defer { if access { url.stopAccessingSecurityScopedResource() } }
                    let document = try SourceDocument.read(url)
                    return PreviewRenderer(bundle: .main).render(document)
                }.value
                html = rendered
                fileName = url.lastPathComponent
            } catch {
                self.error = error.localizedDescription
            }
            loading = false
        }
    }
}

private struct PreviewWebView: NSViewRepresentable {
    let html: String

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        configuration.websiteDataStore = .nonPersistent()
        return WKWebView(frame: .zero, configuration: configuration)
    }

    func updateNSView(_ view: WKWebView, context: Context) {
        guard context.coordinator.html != html else { return }
        context.coordinator.html = html
        view.loadHTMLString(html, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator { var html: String? }
}
