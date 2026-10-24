import Foundation
import UIKit

final class TrollStoreService {
    static let shared = TrollStoreService()
    private init() {}

    var isInstalled: Bool {
        let paths = ["/var/containers/Bundle/Application/.trollstore",
                     "/var/mobile/Library/Preferences/com.opa334.trollstore.plist"]
        for p in paths where FileManager.default.fileExists(atPath: p) { return true }
        if let u = URL(string: "apple-magnifier://"), UIApplication.shared.canOpenURL(u) { return true }
        return false
    }

    @MainActor
    func open() -> Bool {
        guard let u = URL(string: "apple-magnifier://"), UIApplication.shared.canOpenURL(u) else { return false }
        UIApplication.shared.open(u)
        return true
    }
}
