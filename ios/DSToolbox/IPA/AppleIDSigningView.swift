import SwiftUI
struct AppleIDSigningView: View {
    @State private var id = ""; @State private var pwd = ""; @State private var server = ""; @State private var message: String?
    var body: some View {
        Form {
            Section("账号") { TextField("Apple ID", text: $id).keyboardType(.emailAddress); SecureField("密码", text: $pwd) }
            Section("服务") { TextField("Anisette 服务地址", text: $server) }
            if let m = message { Section { Text(m).foregroundStyle(.red) } }
            Section { Button("登录并获取证书") { Task { do { try await AppleIDSigningService.shared.signIn(appleID: id, password: pwd, anisetteServer: URL(string: server)!, deviceUDID: ""); message = "成功" } catch { message = error.localizedDescription } } } }
        }.navigationTitle("Apple ID 自签")
    }
}
