// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI
import WebKit
import OSLog

struct PreviewWebView: NSViewRepresentable {
    let html: String
    let onFailure: (String) -> Void

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        configuration.websiteDataStore = .nonPersistent()
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator
        context.coordinator.prepare(view)
        return view
    }

    func updateNSView(_ view: WKWebView, context: Context) {
        context.coordinator.onFailure = onFailure
        context.coordinator.setHTML(html, in: view)
    }

    static func dismantleNSView(_ view: WKWebView, coordinator: Coordinator) {
        coordinator.stop()
        view.navigationDelegate = nil
        view.stopLoading()
    }

    func makeCoordinator() -> Coordinator { Coordinator(onFailure: onFailure) }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate {
        var onFailure: (String) -> Void
        var active = true
        private static let logger = Logger(subsystem: "org.masonjames.QLColorCode", category: "Preview")
        private var html: String?
        private var rulesReady = false
        private var pendingNavigation: WKNavigation?
        private var finished = false
        private var watchdog: Task<Void, Never>?

        init(onFailure: @escaping (String) -> Void) { self.onFailure = onFailure }

        func prepare(_ view: WKWebView) {
            startWatchdog()
            // WebKit requires network.client to start even for loadHTMLString.
            // Block resource requests before loading anything; source is also
            // escaped, script execution is disabled, and the document has a CSP.
            Task { @MainActor [weak self, weak view] in
                do {
                    let rules = try await WKContentRuleListStore.default().compileContentRuleList(
                        forIdentifier: "QLColorCode-BlockAllResources-v1",
                        encodedContentRuleList: #"[{"trigger":{"url-filter":".*"},"action":{"type":"block"}}]"#)
                    guard let self, self.active, let view else { return }
                    guard let rules else {
                        Self.logger.error("Content rule compilation returned no rules")
                        self.fail("The local preview could not start safely. Try choosing the file again.")
                        return
                    }
                    view.configuration.userContentController.add(rules)
                    self.rulesReady = true
                    if let html = self.html { self.load(html, in: view) }
                } catch {
                    guard let self, self.active else { return }
                    let failure = error as NSError
                    Self.logger.error("Content rule compilation failed: \(failure.domain, privacy: .public) \(failure.code)")
                    self.fail("The local preview could not start safely. Try choosing the file again.")
                }
            }
        }

        func setHTML(_ html: String, in view: WKWebView) {
            guard self.html != html else { return }
            self.html = html
            if rulesReady { load(html, in: view) }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            // Only the in-memory document loaded above is allowed. No external
            // navigation, file URLs, clicked links, frames, or new windows.
            let generatedDocument = navigationAction.navigationType == .other
                && navigationAction.targetFrame?.isMainFrame == true
                && navigationAction.request.url?.absoluteString == "about:blank"
            Self.logger.info("Preview navigation policy: allowed=\(generatedDocument)")
            if !generatedDocument && !finished {
                fail("The preview tried to open an unsupported document and was stopped.")
            }
            return generatedDocument && active ? .allow : .cancel
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard active, let navigation, navigation === pendingNavigation else { return }
            finished = true
            watchdog?.cancel()
            Self.logger.info("Local preview finished loading")
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            report(error)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
                     withError error: Error) {
            report(error)
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            Self.logger.error("Preview web content process terminated")
            fail("The preview renderer stopped. Try choosing the file again.")
        }

        func stop() {
            active = false
            watchdog?.cancel()
        }

        private func load(_ html: String, in view: WKWebView) {
            finished = false
            startWatchdog()
            pendingNavigation = view.loadHTMLString(html, baseURL: nil)
            if pendingNavigation == nil { fail("The local preview could not start. Try choosing the file again.") }
        }

        private func startWatchdog() {
            watchdog?.cancel()
            watchdog = Task { @MainActor [weak self] in
                do { try await Task.sleep(for: .seconds(10)) } catch { return }
                guard let self, self.active else { return }
                Self.logger.error("Local preview timed out")
                self.fail("The preview took too long to load. Try choosing the file again.")
            }
        }

        private func fail(_ message: String) {
            guard active else { return }
            watchdog?.cancel()
            onFailure(message)
        }

        private func report(_ error: Error) {
            let failure = error as NSError
            Self.logger.error("Preview navigation failed: \(failure.domain, privacy: .public) \(failure.code)")
            guard active, !(failure.domain == NSURLErrorDomain && failure.code == NSURLErrorCancelled) else { return }
            fail("The preview could not be displayed. Try choosing the file again.")
        }
    }
}
