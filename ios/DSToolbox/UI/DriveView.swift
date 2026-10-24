import SwiftUI

struct DriveView: View {
    @EnvironmentObject var env: ToolboxEnvironment
    @State private var linkInput = ""
    @State private var resolving = false
    @State private var resolved: ResolvedLink?
    @State private var error: String?
    @State private var showLogin = false

    private var adapter: CloudDriveAdapter? { env.currentAdapter }
    private var isLoggedIn: Bool { env.credential != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("网盘") {
                    Picker("选择", selection: Binding(
                        get: { env.currentKind },
                        set: { env.selectKind($0) }
                    )) {
                        ForEach(DriveKind.allCases) { Text($0.displayName).tag($0) }
                    }
                }
                Section("账号") { accountRow }
                Section("分享链接") {
                    TextField("粘贴分享链接", text: $linkInput)
                        .autocorrectionDisabled().textInputAutocapitalization(.never)
                    Button(resolving ? "解析中..." : "解析") { resolve() }
                        .disabled(resolving || linkInput.isEmpty || !isLoggedIn)
                }
                if let resolved {
                    Section("解析结果") {
                        LabeledContent("文件名", value: resolved.fileName)
                        if let size = resolved.expectedSize {
                            LabeledContent("大小", value: byteString(size))
                        }
                        Button("加入下载") { enqueue(resolved) }
                    }
                }
                if let error { Section { Text(error).foregroundStyle(.red) } }
            }
            .navigationTitle("网盘")
            .sheet(isPresented: $showLogin) { loginSheet }
        }
    }

    @ViewBuilder private var accountRow: some View {
        if isLoggedIn {
            HStack {
                Label("已登录", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                Spacer()
                Button("退出", role: .destructive) {
                    CredentialStore.shared.delete(kind: env.currentKind)
                    env.selectKind(env.currentKind)
                }
            }
        } else {
            Button("登录 \(env.currentKind.displayName)") { showLogin = true }
        }
    }

    @ViewBuilder private var loginSheet: some View {
        if let a = adapter {
            NavigationStack {
                WebLoginView(
                    loginURL: a.loginURL,
                    kindRaw: a.kind.rawValue,
                    requiredCookieNames: a.requiredCookieNames,
                    userAgent: a.userAgent
                ) { _ in
                    env.selectKind(a.kind)
                    showLogin = false
                }
                .navigationTitle("登录 \(a.kind.displayName)")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    private func resolve() {
        guard let a = adapter, let cred = env.credential, let url = URL(string: linkInput) else { return }
        resolving = true; error = nil; resolved = nil
        Task {
            do { resolved = try await a.resolve(url, credential: cred) }
            catch { self.error = error.localizedDescription }
            resolving = false
        }
    }

    private func enqueue(_ r: ResolvedLink) {
        do {
            try DownloadQueue.shared.enqueue(link: r, kind: env.currentKind)
            linkInput = ""; resolved = nil
        } catch { self.error = error.localizedDescription }
    }
}
