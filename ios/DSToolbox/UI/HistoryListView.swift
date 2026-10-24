import SwiftUI

struct HistoryListView: View {
    @ObservedObject private var history = DownloadHistory.shared
    @EnvironmentObject var env: ToolboxEnvironment

    var body: some View {
        List {
            if history.records.isEmpty {
                ContentUnavailableView("暂无历史", systemImage: "clock.arrow.circlepath")
            } else {
                ForEach(history.records) { r in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(r.fileName).lineLimit(1)
                        HStack {
                            Text(byteString(r.size)).font(.caption2).foregroundStyle(.secondary)
                            Spacer()
                            Text(r.completedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions {
                        Button("重下") { redownload(r) }.tint(.blue)
                    }
                }
            }
        }
        .navigationTitle("历史")
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button("清空") { history.clear() }.disabled(history.records.isEmpty)
            }
        }
    }

    private func redownload(_ r: HistoryRecord) {
        guard let url = URL(string: r.urlString) else { return }
        _ = try? env.queue.enqueue(url: url, fileName: r.fileName, credential: nil)
    }
}
