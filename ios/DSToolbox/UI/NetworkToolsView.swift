import SwiftUI

struct NetworkToolsView: View {
    @State private var domain = ""
    @State private var results: [String] = []
    @State private var loading = false
    @State private var ip = "获取中..."
    @ObservedObject private var history = NetworkHistoryStore.shared

    var body: some View {
        Form {
            Section("当前 IP") { Text(ip) }
            Section("DNS 查询") {
                TextField("example.com", text: $domain)
                    .autocorrectionDisabled().textInputAutocapitalization(.never)
                Button(loading ? "查询中..." : "查询") { query() }
                    .disabled(loading || domain.isEmpty)
            }
            if !results.isEmpty {
                Section("结果") {
                    ForEach(results, id: \.self) { Text($0).font(.system(.caption, design: .monospaced)) }
                }
            }
            if !history.entries.isEmpty {
                Section("历史") {
                    ForEach(history.entries) { e in
                        Button {
                            domain = e.domain; results = e.records
                        } label: {
                            VStack(alignment: .leading) {
                                Text(e.domain)
                                Text(e.records.prefix(2).joined(separator: ", "))
                                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                        }
                    }
                    .onDelete { history.remove(at: $0) }
                }
                Section {
                    Button("清空历史", role: .destructive) { history.clear() }
                }
            }
        }
        .navigationTitle("网络工具")
        .onAppear { ip = NetworkDiagnostics.shared.currentIP() ?? "未知" }
    }

    private func query() {
        loading = true
        Task {
            let r = (try? await NetworkDiagnostics.shared.dnsQuery(domain: domain)) ?? []
            results = r
            if !r.isEmpty { history.add(domain: domain, records: r) }
            loading = false
        }
    }
}
