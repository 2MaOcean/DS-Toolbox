import SwiftUI

struct BookmarksSheet: View {
    @ObservedObject private var store = BookmarkStore.shared
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if store.bookmarks.isEmpty {
                    ContentUnavailableView("暂无书签", systemImage: "bookmark")
                } else {
                    List {
                        ForEach(store.bookmarks) { b in
                            Button {
                                onSelect(b.url); dismiss()
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(b.title)
                                    Text(b.url).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete { store.remove(at: $0) }
                    }
                }
            }
            .navigationTitle("书签")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("关闭") { dismiss() } } }
        }
    }
}
