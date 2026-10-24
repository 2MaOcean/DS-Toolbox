import SwiftUI

struct AppleIDSigningView: View {
    @State private var appleID = ""
    @State private var password = ""
    @State private var ipaPath = ""
    @State private var status = ""
    @State private var running = false

    var body: some View {
        Form {
            Section("Apple ID") {
                TextField("账号", text: $appleID).textInputAutocapitalization(.never).autocorrectionDisabled()
                SecureField("密码", text: $password)
            }
            Section("IPA") { TextField("IPA 路径", text: $ipaPath) }
            Section {
                Button(running ? "签名中..." : "开始签名") { sign() }.disabled(running || appleID.isEmpty || password.isEmpty || ipaPath.isEmpty)
                if !status.isEmpty { Text(status).font(.caption).foregroundStyle(.secondary) }
            }
        }
        .navigationTitle("Apple ID 自签")
    }

    private func sign() {
        running = true
        Task {
            do {
                let out = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents/signed.ipa")
                try await AppleIDSigningService.shared.sign(appleID: appleID, password: password, ipa: URL(fileURLWithPath: ipaPath), output: out)
                status = "已生成：\(out.lastPathComponent)"
            } catch { status = error.localizedDescription }
            running = false
        }
    }
}
