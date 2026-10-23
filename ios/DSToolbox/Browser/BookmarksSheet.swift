import SwiftUI
struct BookmarksSheet: View {
    @ObservedObject var store = BookmarkStore.shared
    @ObservedObject var session = BrowserSession.shared
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                ForEach(store.bookmarks) { bm in
                    Button { session.load(bm.url); dismiss() } label: {
                        VStack(alignment: .leading) { Text(bm.title).font(.headline); Text(bm.url).font(.caption).foregroundStyle(.secondary).lineLimit(1) }
                    }.swipeActions { Button(role: .destructive) { store.remove(bm.id) } label: { Label("删除", systemImage: "trash") } }
                }
            }.navigationTitle("书签").toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加当前页") { if let tab = session.activeTab, !tab.urlString.isEmpty { store.add(title: tab.title, url: tab.urlString) } }
                }
            }
        }
    }
}
