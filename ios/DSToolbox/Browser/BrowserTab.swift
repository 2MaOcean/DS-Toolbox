import Foundation
import Combine
import WebKit

@MainActor
final class BrowserTab: ObservableObject, Identifiable {
    let id = UUID()
    @Published var title: String = "新标签页"
    @Published var urlString: String = ""
    @Published var isLoading: Bool = false
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var progress: Double = 0
    @Published var isDesktopMode: Bool = false
    let webView: WKWebView

    init() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.allowsBackForwardNavigationGestures = true
        self.webView = wv
    }
}
