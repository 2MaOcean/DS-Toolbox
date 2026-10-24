import SwiftUI

struct LaraIntegrationView: View {
    @ObservedObject private var env = LaraEnvironment.shared
    @ObservedObject private var kc = KernelcacheAutoResolver.shared
    @ObservedObject private var sb = SpringBoardManager.shared
    @ObservedObject private var jit = StikDebugJIT.shared

    var body: some View {
        Form {
            Section("环境") {
                if let i = env.info {
                    LabeledContent("iOS", value: i.iosVersion)
                    LabeledContent("芯片", value: i.chip.rawValue)
                    LabeledContent("排除芯片", value: i.isExcludedChip ? "是" : "否")
                    LabeledContent("KRW", value: i.hasKRW ? "就绪" : "未就绪")
                    LabeledContent("偏移量", value: i.hasOffsets ? "就绪" : "缺失")
                    if let r = i.blockedReason { Text(r).font(.caption).foregroundStyle(.orange) }
                } else {
                    Button("检测环境") { env.refresh() }
                }
            }
            Section("Kernelcache") {
                Text(kc.status).font(.caption)
                Button("自动下载并解析") {
                    Task { _ = await kc.autoFetchAndResolve(); env.refresh() }
                }
                Button("清除数据", role: .destructive) { kc.deleteData(); env.refresh() }
            }
            Section("JIT") {
                Text(jit.status).font(.caption)
            }
            Section("SpringBoard") {
                Toggle("字体覆盖", isOn: $sb.fontOverwrite)
                Toggle("5 应用坞", isOn: $sb.fiveAppDock)
                Toggle("隐藏标签", isOn: $sb.hideLabels)
                Toggle("OTA 禁用", isOn: $sb.otaDisabled)
                Button("应用更改") { Task { _ = await sb.applyAll() } }
            }
            Section("TrollStore") {
                if TrollStoreBridge.shared.isInstalled {
                    Text("已安装").foregroundStyle(.green)
                } else {
                    Text("未安装").foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Lara 集成")
        .onAppear { env.refresh() }
    }
}
