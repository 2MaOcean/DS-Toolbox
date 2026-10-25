import SwiftUI

struct TSToolsView: View {
    @AppStorage("ds.allowExploit") private var allowExploit = false
    @AppStorage("ds.allowAI") private var allowAI = false
    @State private var showStikDebugAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            List {
                if allowAI {
                    Section("AI") { NavigationLink("AI 助手", destination: AIChatView()) }
                }
                if allowExploit {
                    Section("高级") {
                        NavigationLink("Lara 全功能", destination: LaraFullFeaturesView())
                        NavigationLink("Lara 集成", destination: LaraIntegrationView())
                        NavigationLink("漏洞调度", destination: ExploitSettingsView())
                        NavigationLinkLink("内部工具", destination: InternalToolsView())
                    }
                    Section("StikDebug 桥接") {
                        Button("启动应用并启用 JIT") {
                            if StikDebugProvider.shared.isInstalled {
                                _ = StikDebugProvider.shared.openJIT()
                            } else {
                                alertMessage = "未安装 StikDebug"
                                showStikDebugAlert = true
                            }
                        }
                        Button("启动应用（不调试）") {
                            if StikDebugProvider.shared.isInstalled {
                                // 需要用户在 StikDebug 内选择
                                _ = StikDebugProvider.shared.launchApp(bundleID: "")
                            } else {
                                alertMessage = "未安装 StikDebug"
                                showStikDebugAlert = true
                            }
                        }
                        Button("结束进程") {
                            if StikDebugProvider.shared.isInstalled {
                                // 需要用户输入 PID
                                _ = StikDebugProvider.shared.killProcess(pid: 0)
                            } else {
                                alertMessage = "未安装 StikDebug"
                                showStikDebugAlert = true
                            }
                        }
                    }
                }
                Section("系统") {
                    NavigationLink("系统监控", destination: SystemMonitorView())
                    NavigationLink("网络工具", destination: NetworkToolsView())
                    NavigationLink("保活", destination: KeepAliveView())
                }
                Section("工具") {
                    Navigation("垃圾清理", destination: CleanupView())
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
            .alert("提示", isPresented: $showStikDebugAlert) {
                Button("好", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }
}
