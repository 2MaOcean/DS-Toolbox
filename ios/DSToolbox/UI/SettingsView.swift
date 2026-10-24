import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var env: ToolboxEnvironment
    @AppStorage("ds.allowExploit") private var allowExploit = false
    @AppStorage("ds.allowAI") private var allowAI = false
    @State private var showPicker = false

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            Form {
                if allowAI {
                    Section("AI") {
                        NavigationLink("AI 助手", destination: AIChatView())
                        NavigationLink("AI 设置", destination: AISettingsView())
                        NavigationLink("网页 AI", destination: WebAIView())
                    }
                }
                if allowExploit {
                    Section("高级") {
                        NavigationLink("漏洞调度", destination: ExploitSettingsView())
                        NavigationLink("StikDebug", destination: StikDebugGuideView())
                    }
                }
                Section("下载") {
                    Button("选择下载目录") { showPicker = true }
                    Text(DownloadDestinationService.shared.displayName)
                        .font(.caption).foregroundStyle(.secondary)
                    NavigationLink("下载参数", destination: DownloadOptionsView(host: nil))
                }
                Section("凭证") {
                    NavigationLink("站点凭证", destination: SiteCredentialListView())
                }
                Section("文件管理") {
                    Toggle("双栏模式", isOn: $env.dualPaneEnabled)
                }
                Section("关于") {
                    LabeledContent("版本", value: version)
                    LabeledContent("环境", value: CapabilityDetector.shared.capability.rawValue)
                    LabeledContent("芯片", value: CapabilityDetector.shared.chipFamily.rawValue)
                }
            }
            .navigationTitle("设置")
            .sheet(isPresented: $showPicker) {
                DirectoryPickerView { url in
                    showPicker = false
                    try? DownloadDestinationService.shared.setDirectory(url)
                }
            }
        }
    }
}
