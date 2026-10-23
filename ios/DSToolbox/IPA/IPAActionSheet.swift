import SwiftUI
struct IPAActionSheet: View {
    let ipa: ImportedIPA; let onMessage: (String) -> Void; @Environment(\.dismiss) private var dismiss; @ObservedObject private var store = CertificateStore.shared; @State private var method: InstallMethod = .trollStore
    var body: some View {
        NavigationStack {
            Form {
                Section("IPA") { Text(ipa.appName ?? ipa.fileName) }
                Section("安装方式") { Picker("方式", selection: $method) { Text("TrollStore").tag(InstallMethod.trollStore); Text("OTA 安装").tag(InstallMethod.itmsServices) }.pickerStyle(.segmented) }
                Section { Button("直接安装 (未签名)") { Task { try? await IPAInstallService.shared.install(ipa: ipa.fileURL, using: method); dismiss() } }.disabled(ipa.isEncrypted) }
            }.navigationTitle("安装").toolbar { ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } } }
        }
    }
}
