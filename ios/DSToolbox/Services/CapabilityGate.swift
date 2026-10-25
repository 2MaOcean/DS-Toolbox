import Foundation
import Combine

@MainActor
final class CapabilityGate: ObservableObject {
    static let shared = CapabilityGate()
    @Published private(set) var canUseKRWFiles = false
    @Published private(set) var canManageProcesses = false
    @Published private(set) var canUseTrollStore = false
    @Published private(set) var canUseDarkSword = false
    @Published private(set) var canUseSystemMonitor = false
    private init() { refresh() }

    func refresh() {
        canUseTrollStore = TrollStoreService.shared.isInstalled
        canUseDarkSword = DarkSwordKRW.shared.isReady
        canUseKRWFiles = canUseDarkSword || FileManager.default.fileExists(atPath: "/var/jb")
        canManageProcesses = hasGetTaskAllow() || canUseTrollStore || FileManager.default.fileExists(atPath: "/var/jb")
        canUseSystemMonitor = true
    }

    private func hasGetTaskAllow() -> Bool {
        // 读自身 entitlements
        guard let path = Bundle.main.executablePath else { return false }
        return hasEntitlement(path: path, key: "get-task-allow")
    }

    private func hasEntitlement(path: String, key: String) -> Bool {
        var code: SecStaticCode?
        guard SecStaticCodeCreateWithPath(URL(fileURLWithPath: path) as CFURL, [], &code) == errSecSuccess,
              let code else { return false }
        var info: CFDictionary?
        guard SecCodeCopySigningInformation(code, SecCSFlags(rawValue: kSecCSSigningInformation), &info) == errSecSuccess,
              let dict = info as? [String: Any],
              let ents = dict["entitlements-dict"] as? [String: Any] else { return false }
        return (ents[key] as? Bool) == true
    }
}
