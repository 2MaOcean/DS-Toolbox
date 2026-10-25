import SwiftUI

struct InternalToolsView: View {
    @ObservedObject private var kc = KernelcacheAutoResolver.shared
    @State private var ipswURL = ""
    @State private var pidInput = ""

    var body: some View {
        Form {
            Section("Kernelcache") {
                Text(kc.status).font(.caption)
                TextField("IPSW 直链", text: $ipswURL)
                    .autocorrectionDisabled().textInputAutocapitalization(.never)
                Button("下载并解析") {
                    Task { _ = await kc.autoFetchAndResolve(ipswURL: ipswURL.isEmpty ? nil : ipswURL) }
                }
            }
            Section("JIT") {
                TextField("PID", text: $pidInput).keyboardType(.numberPad)
                Button("启用") {
                    if let p = Int32(pidInput) { _ = StikDebugJIT.shared.enableJIT(pid: p) }
                }.disabled(pidInput.isEmpty)
            }
        }
        .navigationTitle("内部工具")
    }
}
