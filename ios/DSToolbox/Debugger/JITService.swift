import Foundation
import UIKit
final class JITService {
    static let shared = JITService(); private init() {}
    var isStikDebugInstalled: Bool { UIApplication.shared.canOpenURL(URL(string: "stikjit://")!) }
    func enableJIT(bundleID: String) -> Bool {
        guard isStikDebugInstalled, let url = URL(string: "stikjit://enable-jit?bundle-id=\(bundleID)") else { return false }
        UIApplication.shared.open(url); return true
    }
    func openStikDebugStore() { UIApplication.shared.open(URL(string: "https://apps.apple.com/app/stikdebug/id6504630505")!) }
}
