import Foundation
import WebKit
import Combine

@MainActor
final class BrowserSession: NSObject, ObservableObject {
    static let shared = BrowserSession()
    @Published var tabs: [BrowserTab] = []
    @Published var activeTabID: UUID?
    @Published var pendingDownload: PendingDownload?

    struct PendingDownload: Identifiable {
        let id = UUID()
        let url: URL
        let suggestedFileName: String
        let host: String
    }

    var activeTab: BrowserTab? { tabs.first { $0.id == activeTabID } }

    private override init() {
        super.init()
        newTab()
    }

    func newTab(url: URL? = nil) {
        let tab = BrowserTab()
        tab.webView.navigationDelegate = self
        tab.webView.uiDelegate = self
        if let url = url { tab.webView.load(URLRequest(url: url)) }
        tabs.append(tab)
        activeTabID = tab.id
    }

    func closeTab(_ id: UUID) {
        tabs.removeAll { $0.id == id }
        if activeTabID == id { activeTabID = tabs.last?.id }
        if tabs.isEmpty { newTab() }
    }

    func load(_ urlString: String) {
        guard let tab = activeTab else { return }
        var input = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !input.contains("://") { input = "https://" + input }
        guard let url = URL(string: input) else { return }
        tab.webView.load(URLRequest(url: url))
    }

    func captureCookies(for host: String) {
        guard let tab = activeTab else { return }
        tab.webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            let filtered = cookies.filter { host.hasSuffix($0.domain) || $0.domain.hasSuffix(host) }
            guard !filtered.isEmpty else { return }
            let header = SiteCredentialStore.headerFromCookies(filtered)
            let ua = tab.webView.customUserAgent ?? "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15"
            SiteCredentialStore.shared.save(host: host, cookieHeader: header, userAgent: ua)
        }
    }
}

extension BrowserSession: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        updateTab(for: webView) { $0.isLoading = true }
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateTab(for: webView) {
            $0.isLoading = false; $0.title = webView.title ?? "无标题"
            $0.urlString = webView.url?.absoluteString ?? ""
            $0.canGoBack = webView.canGoBack; $0.canGoForward = webView.canGoForward
        }
        if let host = webView.url?.host { captureCookies(for: host) }
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(navigationAction.shouldPerformDownload ? .download : .allow)
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(navigationResponse.canShowMIMEType ? .allow : .download)
    }
    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) { download.delegate = self }
    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) { download.delegate = self }
    private func updateTab(for webView: WKWebView, _ block: (inout BrowserTab) -> Void) {
        guard let idx = tabs.firstIndex(where: { $0.webView === webView }) else { return }
        var tab = tabs[idx]; block(&tab); tabs[idx] = tab
    }
}

extension BrowserSession: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil { webView.load(navigationAction.request) }
        return nil
    }
}

extension BrowserSession: WKDownloadDelegate {
    nonisolated func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let url = response.url; let host = url?.host ?? ""
        Task { @MainActor in
            if let url = url { self.pendingDownload = PendingDownload(url: url, suggestedFileName: suggestedFilename, host: host) }
            completionHandler(nil)
        }
    }
}
