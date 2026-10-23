import SwiftUI

struct TaskDetailView: View {
    let task: DownloadTask
    @EnvironmentObject var env: ToolboxEnvironment
    @State private var segmentTotal = 0
    @State private var segmentDone = 0
    @State private var exportingURL: URL?

    private var currentTask: DownloadTask { env.queue.tasks.first(where: { $0.id == task.id }) ?? task }

    var body: some View {
        Form {
            Section("文件") {
                LabeledContent("文件名", value: currentTask.fileName)
                LabeledContent("大小", value: byteString(currentTask.totalBytes))
                LabeledContent("已完成", value: byteString(currentTask.completedBytes))
            }
            Section("状态") {
                LabeledContent("状态", value: statusText(currentTask))
                LabeledContent("重试", value: "\(currentTask.retries)")
                LabeledContent("创建时间", value: currentTask.createdAt.formatted(date: .abbreviated, time: .shortened))
            }
            if segmentTotal > 0 {
                Section("分片") {
                    LabeledContent("已完成 / 总数", value: "\(segmentDone) / \(segmentTotal)")
                    ProgressView(value: segmentTotal > 0 ? Double(segmentDone) / Double(segmentTotal) : 0)
                }
            }
            Section("链接") {
                Text(currentTask.url.absoluteString).font(.caption).textSelection(.enabled)
                ShareLink(item: currentTask.url) { Label("分享直链", systemImage: "square.and.arrow.up") }
            }

            Section("操作") {
                switch currentTask.state {
                case .running, .queued: Button("暂停") { env.queue.pause(id: task.id) }
                case .paused, .failed: Button("继续") { env.queue.resume(id: task.id) }
                case .finished:
                    if FileManager.default.fileExists(atPath: currentTask.destination.path) {
                        Button("导出到文件") { exportingURL = currentTask.destination }
                        NavigationLink("查看文件") { FileViewer(url: currentTask.destination) }
                    }
                }
                Button("删除任务", role: .destructive) { env.queue.remove(id: task.id) }
            }
        }
        .navigationTitle("任务详情").navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let url = task.taskDirectory.appendingPathComponent("manifest.json")
            if let d = try? Data(contentsOf: url), let m = try? JSONDecoder().decode(DownloadManifest.self, from: d) {
                segmentTotal = m.segments.count; segmentDone = m.completedIndexes.count
            }
        }
        .sheet(item: Binding(get: { exportingURL.map { ExportWrapper(url: $0) } }, set: { exportingURL = $0?.url })) { w in DocumentExporter(urls: w.urls) }
    }

    private func statusText(_ t: DownloadTask) -> String {
        switch t.state { case .queued: return "排队"; case .running: return "下载中"; case .paused: return "暂停"; case .finished: return "完成"; case .failed: return "失败" }
    }
}
