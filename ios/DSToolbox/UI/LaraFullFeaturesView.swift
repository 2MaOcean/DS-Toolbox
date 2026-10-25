import SwiftUI

struct LaraFullFeaturesView: View {
    @ObservedObject private var env = LaraEnvironment.shared
    @ObservedObject private var sb = SpringBoardManager.shared
    @ObservedObject private var mg = MobileGestaltEditor.shared
    @ObservedObject private var apps = AppManagement.shared
    @ObservedObject private var icons = IconTheming.shared
    @ObservedObject private var dz = DirtyZero2.shared
    @State private var mgKey = ""
    @State private var mgValue = ""

    var body: some View {
        Form {
            Section("环境") {
                if let i = env.info {
                    LabeledContent("iOS", value: i.iosVersion)
                    LabeledContent("芯片", value: i.chip.rawValue)
                    LabeledContent("KRW", value: i.hasKRW ? "就绪" : "未就绪")
                    if let r = i.blockedReason { Text(r).font(.caption).foregroundStyle(.orange) }
                } else {
                    Button("检测环境") { env.refresh() }
                }
            }
            Section("MobileGestalt") {
                Button("加载") { mg.load() }
                TextField("键", text: $mgKey).autocorrectionDisabled()
                TextField("值", text: $mgValue).autocorrectionDisabled()
                Button("写入") { if !mgKey.isEmpty { _ = mg.set(key: mgKey, value: mgValue) } }
                    .disabled(mgKey.isEmpty)
            }
            Section("SpringBoard") {
                Toggle("5 应用坞", isOn: $sb.fiveAppDock)
                Toggle("隐藏标签", isOn: $sb.hideLabels)
                Toggle("性能 HUD", isOn: $sb.performanceHUD)
                Toggle("OTA 禁用", isOn: $sb.otaDisabled)
                Button("应用并 respring") { Task { _ = await sb.applyAll(); sb.respring() } }
            }
            Section("应用管理") {
                Button("扫描") { apps.scan() }
                ForEach(apps.apps) { a in
                    HStack { Text(a.name); Spacer(); Button("清缓存") { _ = apps.clearCache(a) } }
                }
            }
            Section("图标主题") {
                Button("恢复默认") { _ = icons.restore() }
            }
            Section("DirtyZero2") {
                Text(dz.status).font(.caption)
                Button("respring") { dz.respring() }
            }
        }
        .navigationTitle("Lara 全功能")
        .onAppear { env.refresh() }
    }
}
