import SwiftUI

struct LaraFeaturesView: View {
    @ObservedObject private var env = EnvironmentManager.shared
    @ObservedObject private var kc = KernelcacheManager.shared
    @ObservedObject private var force = ForceAttemptEngine.shared
    @ObservedObject private var tweaks = SpringBoardTweaks.shared
    @ObservedObject private var decryptor = AppDecryptor.shared

    var body: some View {
        Form {
            Section("环境") {
                if let i = env.info {
                    LabeledContent("iOS", value: i.iosVersion)
                    LabeledContent("芯片", value: i.chip.rawValue)
                    LabeledContent("排除芯片", value: i.isExcludedChip ? "是" : "否")
                    LabeledContent("偏移量", value: i.hasOffsets ? "就绪" : "缺失")
                    if let r = i.blockedReason {
                        Text(r).font(.caption).foregroundStyle(.orange)
                    }
                } else {
                    Button("检测环境") { env.refresh() }
                }
            }
            Section("Kernelcache") {
                Text(kc.status).font(.caption)
                Button("自动获取") {
                    Task { _ = await kc.fetchAutomatically(); env.refresh() }
                }
                Button("清除数据", role: .destructive) {
                    kc.deleteData(); env.refresh()
                }
            }
            Section("强制尝试") {
                Picker("方式", selection: Binding(
                    get: { force.method },
                    set: { force.setMethod($0) }
                )) {
                    ForEach(ForceAttemptEngine.AttemptMethod.allCases) {
                        Text($0.rawValue).tag($0)
                    }
                }
                Button(force.running ? "运行中..." : "强制尝试") {
                    Task { _ = await force.run(force: true) }
                }
            }
            Section("SpringBoard") {
                Toggle("字体覆盖", isOn: $tweaks.fontOverwrite)
                Toggle("5 应用坞", isOn: $tweaks.fiveAppDock)
                Toggle("隐藏标签", isOn: $tweaks.hideLabels)
                Toggle("性能 HUD", isOn: $tweaks.performanceHUD)
                Toggle("OTA 禁用", isOn: $tweaks.otaDisabled)
                Toggle("屏幕使用时间禁用", isOn: $tweaks.screenTimeDisabled)
                Toggle("3 应用绕过", isOn: $tweaks.threeAppBypass)
                Button("应用更改") { Task { _ = await tweaks.apply() } }
            }
            Section("应用解密") {
                Button("扫描可解密应用") { decryptor.scan() }
                ForEach(decryptor.apps) { app in
                    Button {
                        Task { _ = await decryptor.decrypt(app) }
                    } label: {
                        HStack {
                            Text(app.name)
                            Spacer()
                            Text(app.decrypted ? "已解密" : "解密")
                                .foregroundStyle(app.decrypted ? .green : .blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Lara 功能")
        .onAppear { env.refresh() }
    }
}
