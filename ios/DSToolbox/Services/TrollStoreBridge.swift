import Foundation
import UIKit

final class TrollStoreBridge {
    static let shared = TrollStoreBridge()
    private init() {}

    /// TrollStore 1.3+ 使用 apple-magnifier:// 隐藏自己[reference:3]
    var isInstalled: Bool {
        let paths = [
            "/var/containers/Bundle/Application/.trollstore",
            "/var/mobile/Library/Preferences/com.opa334.trollstore.plist"
        ]
        for p in paths where FileManager.default.fileExists(atPath: p) { return true }
        if let u = URL(string: "apple-magnifier://"), UIApplication.shared.canOpenURL(u) { return true }
        return false
    }

    @MainActor
    func installIPA(at url: URL) -> Bool {
        let encoded = url.path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let scheme = URL(string: "apple-magnifier://install?url=\(encoded)"),
              UIApplication.shared.canOpenURL(scheme) else { return false }
        UIApplication.shared.open(scheme)
        return true
    }

    @MainActor
    func open() -> Bool {
        guard let u = URL(string: "apple-magnifier://"),
              UIApplication.shared.canOpenURL(u) else { return false }
        UIApplication.shared.open(u)
        return true
    }
}
