import Foundation
import Combine
import WebKit

@MainActor
final class TorrentDownloader: NSObject, ObservableObject {
    @Published var progress: Double = 0
    @Published var speed: String = ""
    @Published var name: String = ""
    @Published var status: String = "就绪"
    @Published var isRunning: Bool = false
    @Published var savedURL: URL?
    var webView: WKWebView?; var outputHandle: FileHandle?; var outputURL: URL?

    static let html = """
    <!DOCTYPE html><html><head><meta charset="utf-8"></head><body>
    <script src="https://cdn.jsdelivr.net/npm/webtorrent@2.1.36/webtorrent.min.js"></script>
    <script>
    window.startTorrent = function(magnet) {
      if (window.client) { try { window.client.destroy(); } catch(e){} }
      const client = new WebTorrent(); window.client = client;
      client.on('error', e => window.webkit.messageHandlers.torrent.postMessage({type:'error', message: String(e)}));
      const t = client.add(magnet);
      t.on('download', () => { window.webkit.messageHandlers.torrent.postMessage({type:'progress', progress: t.progress, speed: t.downloadSpeed, name: t.name || ''}); });
      t.on('done', () => {
        const f = t.files[0]; if (!f) { window.webkit.messageHandlers.torrent.postMessage({type:'error', message:'无文件'}); return; }
        window.webkit.messageHandlers.torrent.postMessage({type:'start', name: f.name, length: f.length});
        const chunk = 64 * 1024; let offset = 0;
        function send() {
          const end = Math.min(offset + chunk, f.length); const blob = f.slice(offset, end); const r = new FileReader();
          r.onload = () => { window.webkit.messageHandlers.torrent.postMessage({type:'chunk', data: r.result.split(',')[1]}); offset = end; if (offset < f.length) { send(); } else { window.webkit.messageHandlers.torrent.postMessage({type:'complete'}); } };
          r.readAsDataURL(blob);
        }
        send();
      });
    };
    </script></body></html>
    """

    func start(magnet: String) {
        progress = 0; speed = ""; name = ""; status = "连接中…"; isRunning = true; savedURL = nil; outputHandle = nil; outputURL = nil
        let config = WKWebViewConfiguration(); config.websiteDataStore = .nonPersistent()
        let controller = WKUserContentController(); controller.add(self, name: "torrent"); config.userContentController = controller
        let wv = WKWebView(frame: .zero, configuration: config); self.webView = wv
        wv.loadHTMLString(Self.html, baseURL: URL(string: "https://cdn.jsdelivr.net"))
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self, let wv = self.webView else { return }
            let escaped = magnet.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "'", with: "\\'")
            wv.evaluateJavaScript("window.startTorrent('\(escaped)');", completionHandler: nil)
        }
    }

    func stop() {
        webView?.evaluateJavaScript("if(window.client){window.client.destroy();}", completionHandler: nil)
        webView = nil; isRunning = false; status = "已停止"; try? outputHandle?.close(); outputHandle = nil
    }
    func stopWebOnly() { webView?.evaluateJavaScript("if(window.client){window.client.destroy();}", completionHandler: nil); webView = nil }
}
