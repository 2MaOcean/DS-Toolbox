import SwiftUI

struct SiteCredentialListView: View {
    @ObservedObject var store = SiteCredentialStore.shared
    var body: some View {
        List {
            if store.credentials.isEmpty { ContentUnavailableView("还没有保存的站点", systemImage: "globe", description: Text("在浏览器中登录网站后会自动保存凭证")) }
            ForEach(store.credentials) { cred in
                NavigationLink { DownloadOptionsView(host: cred.host) } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(cred.displayName).font(.headline)
                        Text(cred.host).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .swipeActions { Button(role: .destructive) { store.delete(host: cred.host) } label: { Label("删除", systemImage: "trash") } }
            }
        }
        .navigationTitle("站点凭证")
    }
}
