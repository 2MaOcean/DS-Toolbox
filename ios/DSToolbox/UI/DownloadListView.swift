import SwiftUI

struct DownloadListView: View {
    @EnvironmentObject var env: ToolboxEnvironment
    @State private var exportingURL: URL?
    @State private var showAria2 = false
    @State private var searchText = ""
    @State private var filter: Filter = .all
    @State private var previewURL: URL?
    @State private var detailTask: DownloadTask?

    enum Filter: String, CaseIterable, Identifiable {
        case all, active, finished, failed
        var id: String { rawValue }
        var label: String {
            switch self {
            case .all: return "全部"; case .active: return "进行中"; case .finished: return "已完成"; case .failed: return "失败"
            }
        }
    }

    var filteredTasks: [DownloadTask] {
        env.queue.tasks.filter { task in
            let matchSearch = searchText.isEmpty || task.fileName.localizedCaseInsensitiveContains(searchText)
            let matchFilter: Bool = {
                switch filter {
                case .all: return true
                case .active: return task.state == .running || task.state == .queued || task.state == .paused
                case .finished: return task.state == .finished
                case .failed: return task.state == .failed
                }
            }()
            return matchSearch && matchFilter
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Picker("筛选", selection: $filter) {
                    ForEach(Filter.allCases) { f in Text(f.label).tag(f) }
                }.pickerStyle(.segmented).listRowInsets(EdgeInsets())

                if filteredTasks.isEmpty {
                    ContentUnavailableView("没有匹配的任务", systemImage: "arrow.down.circle", description: Text(searchText.isEmpty ? "从网盘页或浏览器拦截开始下载" : "换个关键词试试"))
                }

                ForEach(filteredTasks) { task in row(task) }

                if let packed = env.queue.lastPacked {
                    Section("最近打包") { Text(packed.lastPathComponent).font(.caption) }
                }
            }
            .searchable(text: $searchText, prompt: "搜索文件名")
            .frame(maxWidth: 800).frame(maxWidth: .infinity)
            .navigationTitle("下载")
            .toolbar {
                Button("导入 aria2", systemImage: "square.and.arrow.down") { showAria2 = true }
            }
            .sheet(isPresented: $showAria2) { Aria2ImportView() }
            .sheet(item: Binding(get: { exportingURL.map { ExportWrapper(url: $0) } }, set: { exportingURL = $0?.url })) { (w: ExportWrapper) in DocumentExporter(urls: w.urls) }
            .navigationDestination(item: $previewURL) { url in FileViewer(url: url) }
            .navigationDestination(item: $detailTask) { task in TaskDetailView(task: task) }
        }
    }

    @ViewBuilder
    func row(_ task: DownloadTask) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: FileTypeDetector.iconName(for: task.destination)).foregroundStyle(.tint)
                Text(task.fileName).font(.headline).lineLimit(1)
                Spacer()
                StateBadge(text: statusText(task), color: statusColor(task))
                Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
            }.contentShape(Rectangle()).onTapGesture { detailTask = task }

            ProgressView(value: task.totalBytes > 0 ? Double(task.completedBytes) / Double(task.totalBytes) : 0)
            
            HStack(spacing: 12) {
                if task.state == .running, let speed = env.queue.speeds[task.id] {
                    Text(speedText(speed.bytesPerSecond)).font(.caption2).foregroundStyle(.blue)
                    Text(etaText(task: task, speed: speed.bytesPerSecond)).font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Text(byteString(task.completedBytes) + " / " + byteString(task.totalBytes)).font(.caption2).foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                switch task.state {
                case .running, .queued: Button("暂停") { env.queue.pause(id: task.id) }
                case .paused, .failed: Button("继续") { env.queue.resume(id: task.id) }
                case .finished: Button("导出") { exportingURL = task.destination }; Button("查看") { previewURL = task.destination }
                }
                Button("删除", role: .destructive) { env.queue.remove(id: task.id) }
                Spacer()
            }.font(.caption)
        }.padding(.vertical, 4)
    }

    func speedText(_ bps: Double) -> String { ByteCountFormatter.string(fromByteCount: Int64(bps), countStyle: .file) + "/s" }
    func etaText(task: DownloadTask, speed: Double) -> String {
        guard speed > 0, task.totalBytes > 0 else { return "" }
        let remain = task.totalBytes - task.completedBytes
        guard remain > 0 else { return "" }
        let secs = Int(Double(remain) / speed)
        if secs < 60 { return "剩余 \(secs)s" }
        return String(format: "剩余 %d:%02d", secs / 60, secs % 60)
    }
    func statusText(_ t: DownloadTask) -> String {
        switch t.state { case .queued: return "排队"; case .running: return "下载中"; case .paused: return "暂停"; case .finished: return "完成"; case .failed: return "失败 \(t.retries)" }
    }
    func statusColor(_ t: DownloadTask) -> Color {
        switch t.state { case .finished: return .green; case .failed: return .red; case .paused: return .orange; default: return .blue }
    }
}
