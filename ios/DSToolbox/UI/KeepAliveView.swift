import SwiftUI

struct KeepAliveView: View {
    @ObservedObject private var svc = BackgroundKeepAliveService.shared
    @State private var audioOn = false

    var body: some View {
        Form {
            Section("音频保活") {
                Toggle("静音音频保活", isOn: $audioOn)
                    .onChange(of: audioOn) { _, v in
                        if v { try? svc.startAudioKeepAlive() } else { svc.stop() }
                    }
                Text(svc.isRunning ? "运行中" : "已停止")
                    .font(.caption).foregroundStyle(svc.isRunning ? .green : .secondary)
            }
            Section("说明") {
                Text("开启后播放无声音频，保持 App 在后台持续运行。会消耗少量电池。")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("保活")
    }
}
