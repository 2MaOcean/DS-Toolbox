import SwiftUI

struct TSToolsView: View {
    @AppStorage("ds.allowExploit") private var allowExploit = false
    @AppStorage("ds.allowAI") private var allowAI = false
    @ObservedObject private var gate = CapabilityGate.shared

    var body: some View {
        NavigationStack {
            List {
                environmentSection
                advancedSection
                aiSection
                exploitSection
                krwSection
                processSection
                trollStoreSection
                systemSection
                toolsSection
                downloadSection
                ipaSection
            }
            .navigationTitle("TS 工具")
            .onAppear { gate.refresh() }
        }
    }

    private var isJailbroken: Bool {
        FileManager.default.fileExists(atPath: "/var/jb")
    }

    private var environmentSection: some View {
        Section("当前环境") {
            LabeledContent("签名类型", value: gate.signingType.rawValue)
            LabeledContent("越狱", value: isJailbroken ? "是" : "否")
            LabeledContent("TrollStore", value: gate.canUseTrollStore ? "是" : "否")
            LabeledContent("DarkSword", value: gate.canUseDarkSword ? "就绪" : "未就绪")
            LabeledContent("KRW 文件", value: gate.canUseKRWFiles ? "可用" : "不可用")
            LabeledContent("进程管理", value: gate.canManageProcesses ? "可用" : "不可用")
            LabeledContent("高级总开关", value: gate.canUseAdvanced ? "开" : "关")
        }
    }

    private var advancedSection: some View {
        Section {
            Toggle("允许漏洞 / 越狱功能", isOn: $allowExploit)
            Toggle("允许 AI 功能", isOn: $allowAI)
        } header: {
            Text("高级功能开关")
        } footer: {
            Text("协议页首次勾选后，可在此随时调整。关闭只隐藏入口，不卸载已装组件。")
        }
    }

    @ViewBuilder private var aiSection: some View {
        Section("AI") {
            if allowAI {
                NavigationLink("AI 助手", destination: AIChatView())
            } else {
                Text("已关闭（在“高级功能开关”里打开）")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private var exploitSection: some View {
        Section("Lara / 漏洞利用") {
            if allowExploit {
                NavigationLink("Lara 全功能", destination: LaraFullFeaturesView())
                NavigationLink("Lara 集成", destination: LaraIntegrationView())
                NavigationLink("漏洞调度", destination: ExploitSettingsView())
                if !gate.canUseDarkSword {
                    Text("DarkSword 未就绪：可进“漏洞调度”查看状态")
                        .font(.caption).foregroundStyle(.secondary)
                }
            } else {
                Text("已关闭（在“高级功能开关”里打开）")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private var krwSection: some View {
        Section("文件管理（KRW）") {
            if allowExploit && gate.canUseKRWFiles {
                NavigationLink("根目录浏览", destination: KrwFileBrowserView())
            } else if allowExploit {
                Text("当前环境不支持 KRW（需越狱或 DarkSword 就绪）")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Text("已关闭（在“高级功能开关”里打开）")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private var processSection: some View {
        Section("进程管理") {
            if gate.canManageProcesses {
                NavigationLink("进程列表", destination: ProcessListView())
            } else {
                Text("当前环境不支持进程管理")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private var trollStoreSection: some View {
        Section("TrollStore") {
            if gate.canUseTrollStore {
                NavigationLink("StikDebug", destination: StikDebugGuideView())
            } else {
                Text("未检测到 TrollStore")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var systemSection: some View {
        Section("系统") {
            NavigationLink("系统监控", destination: SystemMonitorView())
            NavigationLink("网络工具", destination: NetworkToolsView())
            NavigationLink("保活", destination: KeepAliveView())
        }
    }

    private var toolsSection: some View {
        Section("工具") {
            NavigationLink("触摸录制", destination: TouchRecorderView())
            NavigationLink("垃圾清理", destination: CleanupView())
            NavigationLink("描述文件", destination: ProfileGeneratorView())
            NavigationLink("应用管理", destination: AppManagerView())
            NavigationLink("插件检查", destination: InjectionInspectorView())
        }
    }

    private var downloadSection: some View {
        Section("下载") {
            NavigationLink("Aria2 导入", destination: Aria2ImportView())
            NavigationLink("种子", destination: TorrentView())
        }
    }

    private var ipaSection: some View {
        Section("IPA") {
            NavigationLink("IPA 管理", destination: IPAManagerView())
            NavigationLink("证书管理", destination: CertificateManagementView())
            NavigationLink("Apple ID 自签", destination: AppleIDSigningView())
        }
    }
}
