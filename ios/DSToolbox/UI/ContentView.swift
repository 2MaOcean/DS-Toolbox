import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var env: ToolboxEnvironment
    @State private var showLogin = false
    @State private var showBrowser = false
    @State private var showRiskAlert = false
    @State private var inputURL = ""
    @State private var alertMessage: String?
    @AppStorage("quark_risk_ack") private var quarkRiskAcknowledged = false

    var body: some View {
        TabView {
            Tab("网盘", systemImage: "cloud") { driveTab }
            Tab("浏览器", systemImage: "safari") { BrowserView() }
            Tab("下载", systemImage: "arrow.down.circle") { DownloadListView() }
            Tab("文件", systemImage: "folder") { FileBrowserView() }
            Tab("BT", systemImage: "point.3.connected.trianglepath.dotted") { TorrentView() }
            Tab("TS 工具", systemImage: "wrench.and.screwdriver") { TSToolsView() }
            Tab("设置", systemImage: "gear") { SettingsView() }
        }
        .tabViewStyle(.sidebarAdaptable)
        .onChange(of: env.queue.needsRelogin) { _, kind in
            guard let kind else { return }
            alertMessage = "\(kind.displayName) 凭证已失效（连续触发限流 3 次）。请重新登录后继续下载。"
            env.queue.needsRelogin = nil
            env.selectKind(kind)
            CredentialStore.shared.delete(kind: kind)
            env.credential = nil
            showLogin = true
        }
        .alert("提示", isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) {
            Button("好", role: .cancel) {}
        } message: { Text(alertMessage ?? "") }
        .alert("夸克网盘风险告知", isPresented: $showRiskAlert) {
            Button("我已了解，继续", role: .destructive) { quarkRiskAcknowledged = true; showLogin = true }
            Button("取消", role: .cancel) {}
        } message: {
            Text("夸克服务协议明确禁止第三方自动化访问。使用本工具下载夸克文件存在账号被中止或永久关闭的风险。建议优先使用官方客户端，或仅用小号测试。")
        }
    }

    private var driveTab: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Picker("网盘", selection: Binding(get: { env.currentKind }, set: { env.selectKind($0) })) {
                        ForEach(DriveKind.allCases) { k in
                            let logged = CredentialStore.shared.load(kind: k) != nil
                            Text("\(k.displayName)\(logged ? "  ✓" : "")").tag(k)
                        }
                    }.pickerStyle(.menu)
                    Text(env.currentKind.tier).font(.caption).foregroundStyle(.secondary)
                    
                    HStack {
                        TextField("分享链接", text: $inputURL).textFieldStyle(.roundedBorder).autocorrectionDisabled().textInputAutocapitalization(.never)
                        Button { if let s = UIPasteboard.general.string { inputURL = s } } label: { Image(systemName: "doc.on.clipboard") }.buttonStyle(.bordered)
                    }
                    
                    HStack(spacing: 12) {
                        Button("解析并下载") { resolveAndDownload() }.buttonStyle(.borderedProminent)
                        Button(env.credential == nil ? "登录" : "已登录 · 重新登录") {
                            if env.currentKind == .quark && !quarkRiskAcknowledged { showRiskAlert = true } else { showLogin = true }
                        }.buttonStyle(.bordered)
                        Button("打开网盘网页") { showBrowser = true }.buttonStyle(.bordered)
                    }
                }.padding()
            }
            .frame(maxWidth: 720).frame(maxWidth: .infinity).navigationTitle("DS 工具箱")
            .sheet(isPresented: $showLogin) {
                if let a = env.currentAdapter {
                    WebLoginView(loginURL: a.loginURL, kindRaw: env.currentKind.rawValue, requiredCookieNames: a.requiredCookieNames, userAgent: a.userAgent) { cred in
                        try? CredentialStore.shared.save(cred); env.credential = cred; showLogin = false
                    }.ignoresSafeArea()
                }
            }
            .sheet(isPresented: $showBrowser) {
                if let a = env.currentAdapter {
                    DownloadBrowserView(url: a.loginURL, userAgent: a.userAgent) { url, name in
                        handleIntercepted(url: url, name: name)
                    }.ignoresSafeArea()
                }
            }
        }
    }

    private func resolveAndDownload() {
        guard let url = URL(string: inputURL) else { alertMessage = "链接无效"; return }
        guard let adapter = env.registry.adapter(for: url) else { alertMessage = "不支持的网盘"; return }
        guard let cred = CredentialStore.shared.load(kind: adapter.kind) else { alertMessage = "请先登录 \(adapter.kind.displayName)"; return }
        Task {
            do {
                let link = try await adapter.resolve(url, credential: cred)
                _ = try env.queue.enqueue(url: link.url, fileName: link.fileName, credential: cred, kind: adapter.kind)
            } catch { alertMessage = error.localizedDescription }
        }
    }

    private func handleIntercepted(url: URL, name: String) {
        guard let cred = CredentialStore.shared.load(kind: env.currentKind) else { alertMessage = "请先登录"; return }
        do {
            _ = try env.queue.enqueue(url: url, fileName: name, credential: cred, kind: env.currentKind)
            showBrowser = false
        } catch { alertMessage = error.localizedDescription }
    }
}
