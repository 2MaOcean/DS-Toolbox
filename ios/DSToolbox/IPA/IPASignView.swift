import SwiftUI

struct IPASignView: View {
    let ipa: ImportedIPA
    @State private var selectedName = ""
    @State private var password = ""
    @State private var status = ""
    @State private var running = false
    private var certs: [SigningCertificate] { CertificateStore.shared.certificates }

    var body: some View {
        Form {
            Section("证书") {
                Picker("选择", selection: $selectedName) {
                    ForEach(certs) { Text($0.name).tag($0.name) }
                }
                SecureField("p12 密码", text: $password)
            }
            Section {
                Button(running ? "签名中..." : "开始签名") { sign() }
                    .disabled(running || selectedName.isEmpty)
                if !status.isEmpty { Text(status).font(.caption).foregroundStyle(.secondary) }
            }
        }
        .navigationTitle("签名")
    }

    private func sign() {
        guard let cert = certs.first(where: { $0.name == selectedName }) else { return }
        running = true
        Task {
            do {
                let out = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let url = try ZSignInAppService.shared.sign(
                    ipa: ipa.fileURL,
                    p12: URL(fileURLWithPath: cert.p12Path),
                    mobileprovision: URL(fileURLWithPath: cert.mobileprovisionPath),
                    password: password,
                    outputDirectory: out
                )
                status = "完成：\(url.lastPathComponent)"
            } catch { status = error.localizedDescription }
            running = false
        }
    }
}
