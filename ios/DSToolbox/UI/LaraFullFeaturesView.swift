import SwiftUI

struct LaraFullFeaturesView: View {
    @ObservedObject private var env = LaraEnvironment.shared
    @ObservedObject private var kc = KernelcacheManager.shared
    @ObservedObject private var force = ForceAttemptEngine.shared
    @ObservedObject private var jit = StikDebugJIT.shared
    @ObservedObject private var sb = SpringBoardManager.shared
    @ObservedObject private var mg = MobileGestaltEditor.shared
    @ObservedObject private var apps = AppManagement.shared
    @ObservedObject private var icons = IconTheming.shared
    @ObservedObject private var dz = DirtyZero2.shared
    @ObservedObject private var decryptor = AppDecryptor.shared
    @State private var mgKey = ""
    @State private var mgValue = ""

    var body: some View {
        Form {
            environmentSection; kernelcacheSection; forceSection
            jitSection; trollStoreSection; springboardSection
            mobileGestaltSection; appManagementSection; iconThemingSection
            dirtyZeroSection; decryptSection
        }
        .navigationTitle("Lara 全功能")
        .onAppear { env.refresh() }
    }

    @ViewBuilder private var environmentSection: some View {
        Section("环境") {
            if let i = env.info {
                LabeledContent("iOS", value: i.iosVersion)
                LabeledContent("芯片", value: i.chip.rawValue)
                LabeledContent("KRW", value: i.hasKRW ? "就绪" : "未就绪")
                LabeledContent("偏移量", value: i.hasOffsets ? "就绪" : "缺失")
                if let r = i.blockedReason { Text(r).font(.caption).foregroundStyle(.orange) }
            } else {
                Button("检测环境") { env.refresh() }
            }
        }
    }

    @ViewBuilder private var kernelcacheSection: some View {
        Section("Kernelcache") {
            Text(kc.status).font(.caption)
            Button("自动获取并解析") { Task { _ = await kc.fetchAutomatically(); env.refresh() } }
            Button("清除数据", role: .destructive) { kc.deleteData(); env.refresh() }
        }
    }

    @ViewBuilder private var forceSection: some View {
        Section("强制尝试") {
            Picker("方式", selection: Binding(
                get: { force.method },
                set: { force.setMethod($0) }
            )) {
                ForEach(ForceAttemptEngine.AttemptMethod.allCases) { Text($0.rawValue).tag($0) }
            }
            Button(force.running ? "运行中..." : "强制执行") {
                Task { _ = await force.run(force: true) }
            }.disabled(force.running)
        }
    }

    @ViewBuilder private var jitSection: some View {
        Section("JIT") { Text(jit.status).font(.caption) }
    }

    @ViewBuilder private var trollStoreSection: some View {
        Section("TrollStore") {
            LabeledContent("状态", value: TrollStoreService.shared.isInstalled ? "已安装" : "未安装")
        }
    }

    @ViewBuilder private var springboardSection: some View {
        Section("SpringBoard") {
            Toggle("5 应用坞", isOn: $sb.fiveAppDock)
            Toggle("隐藏标签", isOn: $sb.hideLabels)
            Toggle("性能 HUD", isOn: $sb.performanceHUD)
            Toggle("OTA 禁用", isOn: $sb.otaDisabled)
            Toggle("3 应用绕过", isOn: $sb.threeAppBypass)
            Text(sb.lastApply).font(.caption)
            Button("应用并 respring") { Task { _ = await sb.applyAll(); sb.respring() } }
        }
    }

    @ViewBuilder private var mobileGestaltSection: some View {
        Section("MobileGestalt") {
            Button("加载") { mg.load() }
            Text(mg.status).font(.caption)
            TextField("键", text: $mgKey).autocorrectionDisabled()
            TextField("值", text: $mgValue).autocorrectionDisabled()
            Button("写入") { if !mgKey.isEmpty { _ = mg.set(key: mgKey, value: mgValue) } }
                .disabled(mgKey.isEmpty)
        }
    }

    @ViewBuilder private var appManagementSection: some View {
        Section("应用管理") {
            Button("扫描") { apps.scan() }
            Text(apps.status).font(.caption)
            ForEach(apps.apps) { a in
                HStack {
                    Text(a.name)
                    Spacer()
                    Button("清缓存") { _ = apps.clearCache(a) }
                }
            }
        }
    }

    @ViewBuilder private var iconThemingSection: some View {
        Section("图标主题") {
            Text(icons.status).font(.caption)
            Button("恢复默认") { _ = icons.restore() }
        }
    }

    @ViewBuilder private var dirtyZeroSection: some View {
        Section("DirtyZero2") {
            Text(dz.status).font(.caption)
            Button("刷新 MG") { _ = dz.refreshMG() }
            Button("respring") { dz.respring() }
        }
    }

    @ViewBuilder private var decryptSection: some View {
        Section("应用解密") {
            Button("扫描") { decryptor.scan() }
            Text(decryptor.status).font(.caption)
            ForEach(decryptor.apps) { a in
                Button {
                    Task { _ = await decryptor.decrypt(a) }
                } label: {
                    HStack {
                        Text(a.name)
                        Spacer()
                        Text(a.decrypted ? "已解密" : "解密")
                            .foregroundStyle(a.decrypted ? .green : .blue)
                    }
                }
            }
        }
    }
}
