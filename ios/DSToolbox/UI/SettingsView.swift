import SwiftUI
struct SettingsView: View {
    @EnvironmentObject var env: ToolboxEnvironment
    @State private var toast: String?
    @State private var showDestinationPicker = false
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink("漏洞利用设置") { ExploitSettingsView() }
                    LabeledContent("沙盒级别", value: SandboxService.shared.level.rawValue)
                    LabeledContent("Entitlements", value: SandboxService.shared.entitlementSummary)
                } header: { Text("安全与恢复") }
                Section("IPA") {
                    NavigationLink("IPA 管理器") { IPAManagerView() }
                    NavigationLink("证书管理") { CertificateManagementView() }
                    NavigationLink("Apple ID 自签") { AppleIDSigningView() }
                }
                Section("下载") {
                    HStack { Text("当前目录"); Spacer(); Text(DownloadDestinationService.shared.displayName).foregroundStyle(.secondary).lineLimit(1) }
                    Button("选择目录") { showDestinationPicker = true }
                    NavigationLink("全局下载参数") { DownloadOptionsView(host: nil) }
                    NavigationLink("站点凭证与参数") { SiteCredentialListView() }
                }
                Section("后台保活") {
                    NavigationLink { KeepAliveView() } label: {
                        HStack { Image(systemName: BackgroundKeepAliveService.shared.isRunning ? "checkmark.seal.fill" : "seal").foregroundStyle(BackgroundKeepAliveService.shared.isRunning ? .green : .secondary); Text(BackgroundKeepAliveService.shared.isRunning ? "运行中" : "未运行"); Spacer() }
                    }
                }
                Section("文件管理") {
                    Toggle("双栏模式", isOn: $env.dualPaneEnabled)
                    NavigationLink("垃圾清理") { CleanupView() }
                    NavigationLink("下载历史") { HistoryListView() }
                }
            }.frame(maxWidth: 720).frame(maxWidth: .infinity).navigationTitle("设置")
            .sheet(isPresented: $showDestinationPicker) { DirectoryPickerView { url in showDestinationPicker = false; try? DownloadDestinationService.shared.setDirectory(url) } }
        }
    }
}
