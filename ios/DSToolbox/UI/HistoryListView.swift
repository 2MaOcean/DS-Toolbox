import SwiftUI
struct HistoryListView: View {
    @EnvironmentObject var env: ToolboxEnvironment; @State private var toast: String?
    var body: some View {
        List {
            ForEach(env.history.records) { record in
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.fileName).font(.headline).lineLimit(1)
                    HStack(spacing: 8) { Text(byteString(record.size)).font(.caption2); Text(record.completedAt.formatted(date: .numeric, time: .shortened)).font(.caption2) }.foregroundStyle(.secondary)
                }.contextMenu {
                    Button { if let u = URL(string: record.urlString), let k = DriveKind(rawValue: record.kind), let c = CredentialStore.shared.load(kind: k) { _ = try? env.queue.enqueue(url: u, fileName: record.fileName, credential: c, kind: k) } } label: { Label("重新下载", systemImage: "arrow.clockwise") }
                }
            }
        }.navigationTitle("下载历史").navigationBarTitleDisplayMode(.inline)
    }
}
