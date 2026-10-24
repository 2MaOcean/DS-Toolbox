import SwiftUI

struct SiteCredentialListView: View {
    @ObservedObject private var store = SiteCredentialStore.shared

    var body: some View {
        List {
            if store.credentials.isEmpty {
                ContentUnavailableView("暂无站点凭证", systemImage: "key")
            } else {
                ForEach(store.credentials) { c in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(c.displayName).font(.headline)
                        Text(c.host).font(.caption).foregroundStyle(.secondary)
                        if c.isStale {
                            Label("已过期", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption2).foregroundStyle(.orange)
                        }
                    }
                    .swipeActions {
                        Button("删除", role: .destructive) { store.delete(host: c.host) }
                    }
                }
            }
        }
        .navigationTitle("站点凭证")
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button("清空") { store.deleteAll() }.disabled(store.credentials.isEmpty)
            }
        }
    }
}
