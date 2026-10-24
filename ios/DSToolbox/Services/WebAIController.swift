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
        // 伪装成桌面版浏览器，防止网页端拦截
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15"
        webView.load(URLRequest(url: URL(string: "https://chat.deepseek.com")!))
    }
    
    /// 自动填充并发送，加入随机间隔防封号
    func autoSend(prompt: String) {
        sendTimer?.invalidate()
        // 设定基础间隔 15 秒，加上随机抖动
        let randomInterval = Double.random(in: 15.0...20.0)
        
        sendTimer = Timer.scheduledTimer(withTimeInterval: randomInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            // 通过 JS 寻找 textarea 输入框，填入内容并触发事件，然后点击发送
            let escapedPrompt = prompt.replacingOccurrences(of: "'", with: "\\'").replacingOccurrences(of: "\n", with: "\\n")
            let js = """
            (function() {
                const input = document.querySelector('textarea');
                // 不同的 AI 网站发送按钮可能不同，这里做了通用兼容
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
}
