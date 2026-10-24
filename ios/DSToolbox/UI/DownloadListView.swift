import SwiftUI

struct DownloadListView: View {
    @EnvironmentObject var env: ToolboxEnvironment

    var body: some View {
        NavigationStack {
            List {
                if env.queue.tasks.isEmpty {
                    ContentUnavailableView("暂无任务", systemImage: "arrow.down.circle")
                } else {
                    ForEach(env.queue.tasks) { task in
                        NavigationLink {
                            TaskDetailView(env: env, taskID: task.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.fileName).lineLimit(1)
                                HStack {
                                    Text(task.state.rawValue).font(.caption2).foregroundStyle(color(for: task.state))
                                    Spacer()
                                    if task.totalBytes > 0 {
                                        Text("\(byteString(task.completedBytes)) / \(byteString(task.totalBytes))")
                                            .font(.caption2).foregroundStyle(.secondary)
                                    }
                                }
                                if task.totalBytes > 0 {
                                    ProgressView(value: Double(task.completedBytes), total: Double(task.totalBytes))
                                }
                            }
                        }
                        .swipeActions {
                            if task.state == .running { Button("暂停") { env.queue.pause(id: task.id) }.tint(.orange) }
                            if task.state == .paused || task.state == .failed { Button("继续") { env.queue.resume(id: task.id) }.tint(.green) }
                            Button("删除", role: .destructive) { env.queue.remove(id: task.id) }
                        }
                    }
                }
            }
            .navigationTitle("下载")
            .toolbar {
                ToolbarItem(placement: .destructiveAction) {
                    Button("全部暂停") { env.queue.pauseAll() }.disabled(env.queue.tasks.isEmpty)
                }
            }
        }
    }

    private func color(for state: TaskState) -> Color {
        switch state {
        case .finished: return .green
        case .failed: return .red
        case .running: return .blue
        case .paused: return .orange
        case .queued: return .secondary
        }
    }
}
