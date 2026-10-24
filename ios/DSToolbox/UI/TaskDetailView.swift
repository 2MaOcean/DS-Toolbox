import SwiftUI

struct TaskDetailView: View {
    @ObservedObject var env: ToolboxEnvironment
    let taskID: UUID
    @State private var exportingURL: URL?

    private var task: DownloadTask? { env.queue.tasks.first { $0.id == taskID } }

    var body: some View {
        Group {
            if let t = task {
                Form {
                    Section("文件") {
                        LabeledContent("名称", value: t.fileName)
                        LabeledContent("总大小", value: byteString(t.totalBytes))
                        LabeledContent("已完成", value: byteString(t.completedBytes))
                        LabeledContent("状态", value: t.state.rawValue)
                        if t.totalBytes > 0 {
                            ProgressView(value: Double(t.completedBytes), total: Double(t.totalBytes))
                        }
                    }
                    Section("链接") {
                        Text(t.url.absoluteString).font(.caption).textSelection(.enabled)
                    }
                    Section("操作") {
                        if t.state == .running { Button("暂停") { env.queue.pause(id: t.id) } }
                        if t.state == .paused || t.state == .failed { Button("继续") { env.queue.resume(id: t.id) } }
                        if t.state == .finished {
                            Button("导出") { exportingURL = t.destination }
                        }
                        Button("删除", role: .destructive) { env.queue.remove(id: t.id) }
                    }
                }
            } else {
                Text("任务不存在").foregroundStyle(.secondary)
            }
        }
        .navigationTitle("任务详情")
        .sheet(item: Binding(
            get: { exportingURL.map { ExportWrapper(url: $0) } },
            set: { exportingURL = $0?.url }
        )) { (w: ExportWrapper) in DocumentExporter(urls: w.urls) }
    }
}
