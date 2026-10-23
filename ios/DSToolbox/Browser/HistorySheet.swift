import SwiftUI
struct HistorySheet: View {
    @ObservedObject var store = BrowserHistoryStore.shared
    @ObservedObject var session = BrowserSession.shared
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                ForEach(store.entries) { e in
                    Button { session.load(e.url); dismiss() } label: {
                        VStack(alignment: .leading) {
                            Text(e.title).font(.headline); Text(e.url).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            Text(e.visitedAt.formatted(date: .numeric, time: .shortened)).font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                }
            }.navigationTitle("历史").toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("清空", role: .destructive) { store.clear() } }
            }
        }
    }
}
