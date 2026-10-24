import SwiftUI

struct HistorySheet: View {
    @ObservedObject private var store = BrowserHistoryStore.shared
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if store.entries.isEmpty {
                    ContentUnavailableView("暂无历史", systemImage: "clock")
                } else {
                    List {
                        ForEach(store.entries) { e in
                            Button {
                                onSelect(e.url); dismiss()
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(e.title).lineLimit(1)
                                    HStack {
                                        Text(e.url).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                        Spacer()
                                        Text(e.visitedAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption2).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .onDelete { store.remove(at: $0) }
                    }
                }
            }
            .navigationTitle("历史")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } }
                ToolbarItem(placement: .destructiveAction) {
                    Button("清空") { store.clear() }.disabled(store.entries.isEmpty)
                }
            }
        }
    }
}
