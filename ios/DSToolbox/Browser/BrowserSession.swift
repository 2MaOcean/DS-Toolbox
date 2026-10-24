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
        newTab(url: URL(string: "https://www.baidu.com"))
    }

    func newTab(url: URL? = nil) {
        let tab = BrowserTab()
        tab.webView.navigationDelegate = self
        tab.webView.uiDelegate = self
        observe(tab)
        if let url { tab.webView.load(URLRequest(url: url)) }
        tabs.append(tab)
        activeTabID = tab.id
    }

    func closeTab(_ id: UUID) {
        tabs.removeAll { $0.id == id }
        if activeTabID == id { activeTabID = tabs.last?.id }
        if tabs.isEmpty { newTab() }
    }
}

extension BrowserSession: WKNavigationDelegate {
    func webView(_ w: WKWebView, decidePolicyFor a: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(a.shouldPerformDownload ? .download : .allow)
    }
    func webView(_ w: WKWebView, decidePolicyFor r: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(r.canShowMIMEType ? .allow : .download)
    }
}

extension BrowserSession: WKUIDelegate {
    func webView(_ w: WKWebView, createWebViewWith c: WKWebViewConfiguration, for a: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if a.targetFrame == nil { w.load(a.request) }
        return nil
    }
}

extension BrowserSession: WKDownloadDelegate {
    func webView(_ w: WKWebView, navigationAction: WKNavigationAction, didBecome d: WKDownload) { d.delegate = self }
    func webView(_ w: WKWebView, navigationResponse: WKNavigationResponse, didBecome d: WKDownload) { d.delegate = self }
    nonisolated func download(_ d: WKDownload, decideDestinationUsing r: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let url = r.url
        let host = url?.host ?? ""
        Task { @MainActor in
            if let url { self.pendingDownload = PendingDownload(url: url, suggestedFileName: suggestedFilename, host: host) }
            completionHandler(nil)
        }
    }
}
