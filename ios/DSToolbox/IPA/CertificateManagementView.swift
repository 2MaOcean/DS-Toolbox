import SwiftUI

struct CertificateManagementView: View {
    @ObservedObject private var store = CertificateStore.shared
    @State private var showAdd = false
    @State private var name = ""
    @State private var p12Path = ""
    @State private var provPath = ""

    var body: some View {
        Form {
            Section("已保存证书") {
                if store.certificates.isEmpty { Text("暂无证书").foregroundStyle(.secondary) }
                ForEach(store.certificates) { c in
                    VStack(alignment: .leading) {
                        Text(c.name).font(.headline)
                        Text(c.p12Path).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .onDelete { idx in store.certificates.enumerated().filter { idx.contains($0.offset) }.forEach { store.remove(name: $0.element.name) } }
            }
            Section {
                Button("添加证书") { showAdd = true }
                if !store.certificates.isEmpty { Button("清空全部", role: .destructive) { store.removeAll() } }
            }
        }
        .navigationTitle("证书管理")
        .sheet(isPresented: $showAdd) { addSheet }
    }

    private var addSheet: some View {
        NavigationStack {
            Form {
                TextField("名称", text: $name)
                TextField("p12 路径", text: $p12Path)
                TextField("mobileprovision 路径", text: $provPath)
            }
            .navigationTitle("添加证书")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { showAdd = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        store.add(SigningCertificate(name: name, p12Path: p12Path, mobileprovisionPath: provPath, expireDate: nil))
                        name = ""; p12Path = ""; provPath = ""; showAdd = false
                    }.disabled(name.isEmpty)
                }
            }
        }
    }
}
