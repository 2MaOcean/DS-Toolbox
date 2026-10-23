import SwiftUI
struct CertificateManagementView: View {
    @ObservedObject var store = CertificateStore.shared
    var body: some View {
        List {
            ForEach(store.certificates) { c in Text(c.displayName).swipeActions { Button("删除", role: .destructive) { store.delete(c) } } }
            if store.certificates.isEmpty { Text("暂无证书").foregroundStyle(.secondary) }
        }.navigationTitle("证书管理")
    }
}
