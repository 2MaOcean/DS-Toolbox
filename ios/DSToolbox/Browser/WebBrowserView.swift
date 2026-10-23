import SwiftUI
import WebKit
import UniformTypeIdentifiers

final class DownloadBrowserCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate {
    let startURL: URL; let userAgent: String; let onDownload: (URL, String) -> Void
    private var pickerDelegate: PickerDelegate?
    init(startURL: URL, userAgent: String, onDownload: @escaping (URL, String) -> Void) { self.startURL = startURL; self.userAgent = userAgent; self.onDownload = onDownload }
    func attach(_ wv: WKWebView) { wv.navigationDelegate = self; wv.uiDelegate = self; wv.customUserAgent = userAgent; wv.load(URLRequest(url: startURL)) }
    func webView(_ w: WKWebView, decidePolicyFor a: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) { decisionHandler(a.shouldPerformDownload ? .download : .allow) }
    func webView(_ w: WKWebView, decidePolicyFor r: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) { decisionHandler(r.canShowMIMEType ? .allow : .download) }
    func webView(_ w: WKWebView, navigationAction: WKNavigationAction, didBecome d: WKDownload) { d.delegate = self }
    func webView(_ w: WKWebView, navigationResponse: WKNavigationResponse, didBecome d: WKDownload) { d.delegate = self }
    func download(_ d: WKDownload, decideDestinationUsing r: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) { if let url = r.url { onDownload(url, suggestedFilename) }; completionHandler(nil) }
}

final class PickerDelegate: NSObject, UIDocumentPickerDelegate {
    let completion: ([URL]?) -> Void
    init(_ c: @escaping ([URL]?) -> Void) { completion = c }
    func documentPicker(_ c: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) { completion(urls) }
}

struct DownloadBrowserView: UIViewRepresentable {
    let url: URL; let userAgent: String; let onDownload: (URL, String) -> Void
    func makeCoordinator() -> DownloadBrowserCoordinator { DownloadBrowserCoordinator(startURL: url, userAgent: userAgent, onDownload: onDownload) }
    func makeUIView(context: Context) -> WKWebView {
        let c = WKWebViewConfiguration(); c.websiteDataStore = .default()
        let wv = WKWebView(frame: .zero, configuration: c); context.coordinator.attach(wv); return wv
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
