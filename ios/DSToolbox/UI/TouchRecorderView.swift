import SwiftUI

struct TouchRecorderView: View {
    @ObservedObject private var recorder = TouchRecorder.shared
    @State private var savedURL: URL?

    var body: some View {
        Form {
            Section("状态") {
                LabeledContent("录制中", value: recorder.isRecording ? "是" : "否")
                LabeledContent("事件数", value: "\(recorder.events.count)")
            }
            Section("操作") {
                if recorder.isRecording {
                    Button("停止", role: .destructive) { recorder.stop() }
                } else {
                    Button("开始录制") { recorder.start() }
                }
                Button("清空") { recorder.clear() }
                    .disabled(recorder.events.isEmpty)
                Button("导出 JSON") { export() }
                    .disabled(recorder.events.isEmpty)
                if let url = savedURL {
                    Text(url.lastPathComponent).font(.caption)
                }
            }
            Section("说明") {
                Text("录制 App 内任意点击的时间戳与坐标，导出 JSON 用于自动化脚本。")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("触摸录制")
    }

    private func export() {
        guard let data = recorder.exportJSON() else { return }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("touch_\(Int(Date().timeIntervalSince1970)).json")
        try? data.write(to: url)
        savedURL = url
    }
}
