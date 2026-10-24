import SwiftUI

struct LaraFullFeaturesView: View {
    @ObservedObject private var env = LaraEnvironment.shared
    @ObservedObject private var kc = KernelcacheDownloader.shared
    @ObservedObject private var jit = InternalJIT.shared
    @ObservedObject private var sb = SpringBoardManager.shared
    @ObservedObject private var mg = MobileGestaltEditor.shared
    @ObservedObject private var apps = AppManagement.shared
    @ObservedObject private var icons = IconTheming.shared
    @ObservedObject private var dz = DirtyZero2.shared
    @State private var ipswURL = ""
    @State private var pidInput = ""
    @State private var mgKey = ""
    @State private var mgValue = ""

    var body: some View {
        Form {
            environmentSection
            kernelcacheSection
            jitSection
            mobileGestaltSection
            springboardSection
            appManagementSection
            iconThemingSection
            dirtyZeroSection
        }
        .navigationTitle("Lara 全功能")
        .onAppear { env.refresh() }
    }

    @ViewBuilder private var environmentSection: some View {
        Section("环境") {
            if let i = env.info {
                LabeledContent("iOS", value: i.iosVersion)
                LabeledContent("芯片", value: i.chip.rawValue)
                LabeledContent("排除芯片", value: i.isExcludedChip ? "是" : "否")
                LabeledContent("KRW", value: i.hasKRW ? "就绪" : "未就绪")
                LabeledContent("偏移量", value: iST.hasOffsets ? "就绪" : "缺失")
                if let r = i.blockedReason {
                    Text(r).font(.caption).foregroundStyle(.orange)
                }
            } else {
                Button("检测环境") { env.refresh() }
            }
        }
    }

    @ViewBuilder private var mobileGestaltSection: some View {
        Section("MobileGestalt") {
            Button("加载当前缓存") { mg.load() }
            Text(mg.status).font(.caption)
            TextField("键（如 hw.model）", text: $mgKey)
                .autocorrectionDisabled().textInputAutocapitalization(.never)
            TextField("值", text: $mgValue)
                .autocorrectionDisabled().textInputAutocapitalization(.never)
            Button("写入") {
                if !mgKey.isEmpty { _ = mg.set(key: mgKey, value: mgValue) }
            }.disabled(mgKey.isEmpty)
        }
    }

    @ViewBuilder private var springboardSection: some View {
        Section("SpringBoard") {
            Toggle("字体覆盖", isOn: $sb.fontOverwrite)
            Toggle("5 应用坞", isOn: $sb.fiveAppDock)
            Toggle("隐藏标签", isOn: $sb.hideLabels)
            Toggle("屏幕倒置", isOn: $sb.upsideDown)
            Toggle("浮动 Dock", isOn: $sb.floatingDock)
            Toggle("网格切换器", isOn: $sb.gridAppSwitcher)
            Toggle("性能 HUD", isOn: $sb.performanceHUD)
            Toggle("OTA 禁用", isOn: $sb.otaDisabled)
            Toggle("屏幕使用时间禁用", isOn: $sb.screenTimeDisabled)
            Toggle("3 应用绕过", isOn: $sb.threeAppBypass)
            Text(sb.lastApply).font(.caption)
            Button("应用并 respring") {
                Task { _ = await sb.applyAll(); sb.respring() }
            }
        }
    }

    @ViewBuilder private var appManagementSection: some View {
        Section("应用管理") {
            Button("扫描应用") { apps.scan() }
            Text(apps.status).font(.caption)
            ForEach(apps.apps) { app in
                HStack {
                    VStack(alignment: .leading) {
                        Text(app.name)
                        Text(byteString(app.sizeBytes)).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("清缓存") { _ = apps.clearCache(app) }.buttonStyle(.bordered)
                }
            }
        }
    }

    @ViewBuilder private var iconThemingSection: some View {
        Section("图标主题") {
            Text(icons.status).font(.caption)
            ForEach(icons.listThemes(), id: \.self) { t in
                Button(t) { _ = icons.apply(theme: t) }
            }
            Button("恢复默认") { _ = icons.restore() }
        }
    }

    @ViewBuilder private var dirtyZeroSection: some View {
        Section("DirtyZero2") {
            Text(dz.status).font(.caption)
            Button("刷新 MG 缓存") { _ = dz.refreshMG() }
            Button("respring") { dz.respring() }
        }
    }
}
