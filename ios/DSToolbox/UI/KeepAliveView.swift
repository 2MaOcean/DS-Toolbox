import SwiftUI
struct KeepAliveView: View {
    @ObservedObject private var svc = BackgroundKeepAliveService.shared
    var body: some View {
        Form {
            Section { HStack { Image(systemName: svc.isRunning ? "checkmark.seal.fill" : "seal").foregroundStyle(svc.isRunning ? .green : .secondary); Text(svc.isRunning ? "运行中 (\(svc.activeMode.label))" : "未运行"); Spacer(); if svc.isRunning { Button("停止", role: .destructive) { svc.stop() } } } }
            Section("保活方式") {
                ForEach(KeepAliveMode.allCases) { m in
                    Button { switch m { case .none: svc.stop(); case .audio: try? svc.startAudioKeepAlive(); case .location: svc.startLocationKeepAlive() } } label: { HStack { Text(m.label).foregroundStyle(.primary); Spacer(); if svc.activeMode == m { Image(systemName: "checkmark").foregroundStyle(.blue) } } }.disabled(svc.activeMode == m)
                }
                Toggle("启动时自动恢复", isOn: $svc.autoResumeOnLaunch)
            }
            Section("定时停止") { Picker("自动停止", selection: $svc.autoStopMinutes) { Text("关闭").tag(0); Text("30分钟").tag(30); Text("1小时").tag(60) } }
            Section("日志") { ForEach(svc.logs) { e in Text(e.event).font(.caption) } }
        }.navigationTitle("后台保活").onDisappear { svc.persistCurrentMode() }
    }
}
