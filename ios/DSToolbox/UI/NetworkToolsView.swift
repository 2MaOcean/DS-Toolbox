import SwiftUI
struct NetworkToolsView: View {
    @State private var domain = ""; @State private var results: [String] = []; @State private var loading = false
    var body: some View {
        Form {
            Section("本机") { LabeledContent("IP", value: NetworkDiagnostics.shared.currentIP() ?? "—") }
            Section("DNS 查询") {
                TextField("域名", text: $domain).keyboardType(.URL).autocorrectionDisabled()
                Button(loading ? "查询中…" : "查询") {
                    loading = true
                    Task { results = (try? await NetworkDiagnostics.shared.dnsQuery(domain: domain)) ?? []; loading = false }
                }.disabled(loading || domain.isEmpty)
            }
            if !results.isEmpty { Section("结果") { ForEach(results, id: \.self) { Text($0).font(.system(.caption, design: .monospaced)) } } }
        }.navigationTitle("网络工具")
    }
}
