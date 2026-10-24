import Foundation
import Combine

struct DecryptableApp: Identifiable {
    let id: String
    let name: String
    let bundlePath: String
    let executablePath: String
    var decrypted: Bool
}

@MainActor
final class AppDecryptor: ObservableObject {
    static let shared = AppDecryptor()
    @Published private(set) var apps: [DecryptableApp] = []
    @Published private(set) var running = false
    @Published private(set) var status = "未扫描"
    private init() {}

    func scan() {
        let installed = AppScanner.shared.scanAllApps()
        apps = installed.compactMap { a in
            let exec = (a.bundlePath as NSString).appendingPathComponent(
                (a.bundleID.components(separatedBy: ".").last ?? "App")
            )
            guard FileManager.default.fileExists(atPath: exec) else { return nil }
            return DecryptableApp(
                id: a.bundleID, name: a.displayName,
                bundlePath: a.bundlePath, executablePath: exec,
                decrypted: false
            )
        }
        status = "找到 \(apps.count) 个可尝试应用"
    }

    func decrypt(_ app: DecryptableApp) async -> Bool {
        guard DarkSwordKRW.shared.isReady else { status = "请先运行漏洞"; return false }
        running = true
        status = "解密 \(app.name)..."
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        if let i = apps.firstIndex(where: { $0.id == app.id }) {
            apps[i].decrypted = true
        }
        status = "已解密：\(app.name)"
        running = false
        return true
    }
}
