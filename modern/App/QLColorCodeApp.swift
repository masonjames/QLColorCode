// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI
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
    private let appIcon = NSImage(named: "AppIcon").map { Image(nsImage: $0) }
        ?? Image(systemName: "doc.text.magnifyingglass")
    @State private var html: String?
    @State private var fileName: String?
    @State private var error: String?
    @State private var renderingError: String?
    @State private var choosingFile = false
    @State private var loading = false
    @State private var previewTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                appIcon
                    .resizable().frame(width: 48, height: 48)
                    .accessibilityHidden(true)
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
            } else if let renderingError {
                ContentUnavailableView("Preview unavailable", systemImage: "doc.badge.ellipsis",
                    description: Text(renderingError))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let html {
                PreviewWebView(html: html) { renderingError = $0 }
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
                    Text("Source previews since 2007.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: 580, alignment: .leading)
                .padding(30).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Divider()
            HStack {
                Text(fileName ?? "Local syntax highlighting. No content downloads.")
                    .lineLimit(1).truncationMode(.middle)
                Spacer()
                Text("Beta preview").foregroundStyle(.secondary)
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
        .onDisappear { previewTask?.cancel() }
    }

    private func preview(_ url: URL) {
        loading = true
        renderingError = nil
        html = nil
        fileName = nil
        previewTask?.cancel()
        previewTask = Task {
            do {
                let rendered = try await PreviewRenderer.preview(url)
                html = rendered
                fileName = url.lastPathComponent
            } catch is CancellationError {
                // Closing the window cancels its pending preview.
            } catch {
                self.error = error.localizedDescription
            }
            loading = false
        }
    }
}
