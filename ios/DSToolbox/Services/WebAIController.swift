import Foundation
import WebKit
import Combine

@MainActor
final class WebAIController: NSObject, ObservableObject {
    static let shared = WebAIController()
    @Published var webView: WKWebView
    private var sendTimer: Timer?
    
    override init() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        webView = WKWebView(frame: .zero, configuration: config)
        super.init()
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15"
        webView.load(URLRequest(url: URL(string: "https://chat.deepseek.com")!))
    }
    
    func autoSend(prompt: String) {
        sendTimer?.invalidate()
        let randomInterval = Double.random(in: 15.0...20.0)
        sendTimer = Timer.scheduledTimer(withTimeInterval: randomInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let escapedPrompt = prompt.replacingOccurrences(of: "'", with: "\\'").replacingOccurrences(of: "\n", with: "\\n")
            let js = """
            (function() {
                const input = document.querySelector('textarea');
                const btn = document.querySelector('button[type="submit"]') || document.querySelector('button[aria-label="Send"]') || document.querySelector('.send-btn');
                if (input && btn) {
                    input.value = '\(escapedPrompt)';
                    input.dispatchEvent(new Event('input', { bubbles: true }));
                    setTimeout(() => btn.click(), 500);
                }
            })();
            """
            self.webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
    
    func stopAutoSend() { sendTimer?.invalidate(); sendTimer = nil }
    deinit { sendTimer?.invalidate() }
}
