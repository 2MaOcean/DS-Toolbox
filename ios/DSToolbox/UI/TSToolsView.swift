import SwiftUI

struct TSToolsView: View {
    @AppStorage("ds.allowExploit") private var allowExploit = false
    @AppStorage("ds.allowAI") private var allowAI = false
    @ObservedObject private var gate = CapabilityGate.shared

    var body: some View {
        NavigationStack {
            List {
                if allowAI {
                    Section("AI") { NavigationLink("AI 助手", destination: AIChatView()) }
                }
                if allowExploit && gate.canUseDarkSword {
                    Section("Lara 全功能") {
                        NavigationLink("Lara 全功能", destination: LaraFullFeaturesView())
                        NavigationLink("Lara 集成", destination: LaraIntegrationView())
                        NavigationLink("漏洞调度", destination: ExploitSettingsView())
                    }
                }
                if gate.canUseKRWFiles {
                    Section("文件管理（KRW）") {
                        NavigationLink("根目录浏览", destination: KrwFileBrowserView())
                    }
                }
                if gate.canManageProcesses {
                    Section("进程管理") {
                        NavigationLink("进程列表", destination: ProcessListView())
                    }
                }
                if gate.canUseTrollStore {
                    Section("TrollStore") {
                        NavigationLink("StikDebug", destination: StikDebugGuideView())
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
            .onAppear { gate.refresh() }
        }
    }
}
