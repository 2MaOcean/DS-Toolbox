import SwiftUI

struct TSToolsView: View {
    @AppStorage("ds.allowExploit") private var allowExploit = false
    @AppStorage("ds.allowAI") private var allowAI = false

    var body: some View {
        NavigationStack {
            List {
                if allowAI {
                    Section("AI") { NavigationLink("AI 助手", destination: AIChatView()) }
                }
                if allowExploit {
                    Section("高级") {
                        NavigationLink("漏洞调度", destination: ExploitSettingsView())
                        NavigationLink("StikDebug", destination: StikDebugGuideView())
                        NavigationLink("JIT 控制", destination: JITControlView())
                    }
                }
                Section("系统") {
                    NavigationLink("系统监控", destination: SystemMonitorView())
                    NavigationLink("网络工具", destination: NetworkToolsView())
                    NavigationLink("保活", destination: KeepAliveView())
                }
                Section("工具") {
                    NavigationLink("垃圾清理", destination: CleanupView())
                    NavigationLink("描述文件", destination: ProfileGeneratorView())
                    NavigationLink("应用管理", destination: AppManagerView())
                    NavigationLink("插件检查", destination: InjectionInspectorView())
                }
                Section("下载") {
                    NavigationLink("Aria2 导入", destination: Aria2ImportView())
                    NavigationLink("种子", destination: TorrentView())
                }
                Section("IPA") {
                    NavigationLink("IPA 管理", destination: IPAManagerView())
                    NavigationLink("证书管理", destination: CertificateManagementView())
                    NavigationLink("Apple ID 自签", destination: AppleIDSigningView())
                }
            }
            .navigationTitle("TS 工具")
        }
    }
}
