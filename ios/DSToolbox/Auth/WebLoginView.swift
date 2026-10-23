import SwiftUI
import WebKit

@MainActor
final class SharedWebSession: NSObject {
    static let shared = SharedWebSession()
    private var webViews: [String: WKWebView] = [:]
    private var syncTimers: [String: Timer] = [:]
    private var userAgents: [String: String] = [:]
    private var activeKind: String?

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(handleMemoryWarning), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    func webView(for kindRaw: String, userAgent: String) -> WKWebView {
        userAgents[kindRaw] = userAgent; activeKind = kindRaw
        if let existing = webViews[kindRaw] { return existing }
        for (kind, wv) in webViews where kind != kindRaw { wv.stopLoading(); wv.loadHTMLString("", baseURL: nil); wv.navigationDelegate = nil; wv.uiDelegate = nil; webViews.removeValue(forKey: kind) }
        let config = WKWebViewConfiguration(); config.websiteDataStore = .default()
        let wv = WKWebView(frame: .zero, configuration: config); wv.customUserAgent = userAgent; webViews[kindRaw] = wv; return wv
    }
    func endActive(kindRaw: String) { if activeKind == kindRaw { activeKind = nil } }
    func startCookieSync(kindRaw: String, userAgent: String) {
        userAgents[kindRaw] = userAgent; syncTimers[kindRaw]?.invalidate()
        syncTimers[kindRaw] = Timer.scheduledTimer(withTimeInterval: 45, repeats: true) { [weak self] _ in Task { @MainActor in self?.syncNow(kindRaw: kindRaw, userAgent: userAgent) } }
        syncNow(kindRaw: kindRaw, userAgent: userAgent)
    }
    func hasResidentSession(kindRaw: String) -> Bool { webViews[kindRaw] != nil || syncTimers[kindRaw] != nil }
    var residentKinds: [String] { Set(webViews.keys).union(syncTimers.keys).sorted() }
    func enterBackground() { for (_, timer) in syncTimers { timer.invalidate() }; syncTimers.removeAll() }
    func enterForeground() { for (kind, ua) in userAgents where syncTimers[kind] == nil { startCookieSync(kindRaw: kind, userAgent: ua) } }
    @objc private func handleMemoryWarning() { Task { @MainActor in for (kind, wv) in webViews where kind != activeKind { wv.stopLoading(); wv.loadHTMLString("", baseURL: nil); wv.navigationDelegate = nil; wv.uiDelegate = nil; webViews.removeValue(forKey: kind) } } }

    func clear(kindRaw: String) async {
        syncTimers[kindRaw]?.invalidate(); syncTimers.removeValue(forKey: kindRaw); userAgents.removeValue(forKey: kindRaw)
        if let wv = webViews.removeValue(forKey: kindRaw) { wv.stopLoading(); wv.loadHTMLString("", baseURL: nil); wv.navigationDelegate = nil; wv.uiDelegate = nil }
        let store = WKWebsiteDataStore.default(); let types = WKWebsiteDataStore.allWebsiteDataTypes()
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in store.removeData(ofTypes: types, modifiedSince: .distantPast) { cont.resume() } }
        if let kind = DriveKind(rawValue: kindRaw) { CredentialStore.shared.delete(kind: kind) }
    }
    private func syncNow(kindRaw: String, userAgent: String) {
        guard let wv = webViews[kindRaw] else { return }
        wv.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            guard !cookies.isEmpty else { return }
            let header = cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
            try? CredentialStore.shared.save(DriveCredential(kind: kindRaw, cookieHeader: header, userAgent: userAgent, savedAt: Date()))
        }
    }
}

final class WebLoginCoordinator: NSObject, WKNavigationDelegate {
    let loginURL: URL; let kindRaw: String; let requiredCookieNames: [String]; let userAgent: String
    let onSuccess: (DriveCredential) -> Void
    private weak var webView: WKWebView?; private var timer: Timer?
    init(loginURL: URL, kindRaw: String, requiredCookieNames: [String], userAgent: String, onSuccess: @escaping (DriveCredential) -> Void) {
        self.loginURL = loginURL; self.kindRaw = kindRaw; self.requiredCookieNames = requiredCookieNames; self.userAgent = userAgent; self.onSuccess = onSuccess
    }
    func attach(_ webView: WKWebView) {
        self.webView = webView; webView.navigationDelegate = self; webView.load(URLRequest(url: loginURL))
        timer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { [weak self] _ in self?.check() }
    }
    private func check() {
        guard let webView else { return }
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self else { return }
            let names = Set(cookies.map(\.name)); guard self.requiredCookieNames.allSatisfy({ names.contains($0) }) else { return }
            let header = cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
            let cred = DriveCredential(kind: self.kindRaw, cookieHeader: header, userAgent: self.userAgent, savedAt: Date())
            DispatchQueue.main.async {
                self.timer?.invalidate(); self.timer = nil
                try? CredentialStore.shared.save(cred)
                SharedWebSession.shared.startCookieSync(kindRaw: self.kindRaw, userAgent: self.userAgent)
                SharedWebSession.shared.endActive(kindRaw: self.kindRaw)
                self.onSuccess(cred)
            }
        }
    }
    deinit { timer?.invalidate() }
}

struct WebLoginView: UIViewRepresentable {
    let loginURL: URL; let kindRaw: String; let requiredCookieNames: [String]; let userAgent: String; let onSuccess: (DriveCredential) -> Void
    func makeCoordinator() -> WebLoginCoordinator { WebLoginCoordinator(loginURL: loginURL, kindRaw: kindRaw, requiredCookieNames: requiredCookieNames, userAgent: userAgent, onSuccess: onSuccess) }
    func makeUIView(context: Context) -> WKWebView { let wv = SharedWebSession.shared.webView(for: kindRaw, userAgent: userAgent); context.coordinator.attach(wv); return wv }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
