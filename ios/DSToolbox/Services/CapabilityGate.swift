import Foundation
import Combine

@MainActor
final class CapabilityGate: ObservableObject {
    static let shared = CapabilityGate()
    @Published private(set) var canUseKRWFiles = false
    @Published private(set) var canManageProcesses = false
    @Published private(set) var canUseTrollStore = false
    @Published private(set) var canUseDarkSword = false
    @Published private(set) var canUseAdvanced = false
    @Published private(set) var signingType: SigningType = .unknown
    private init() { refresh() }

    func refresh() {
        signingType = SigningTypeDetector.shared.type
        canUseTrollStore = TrollStoreService.shared.isInstalled
        canUseDarkSword = DarkSwordKRW.shared.isReady

        let isEnterprise = signingType == .enterprise
        let isAppStore = signingType == .appStore
        let hasGetTaskAllow = Self.hasGetTaskAllow()
        let isJailbroken = FileManager.default.fileExists(atPath: "/var/jb")

        canUseKRWFiles = (canUseDarkSword || isJailbroken) && !isEnterprise
        canManageProcesses = (hasGetTaskAllow || canUseTrollStore || isJailbroken) && !isEnterprise
        canUseAdvanced = !isEnterprise && !isAppStore
    }

    private static func hasGetTaskAllow() -> Bool {
        guard let path = Bundle.main.executablePath else { return false }
        var code: SecStaticCode?
        guard SecStaticCodeCreateWithPath(URL(fileURLWithPath: path) as CFURL, [], &code) == errSecSuccess,
              let code else { return false }
        var info: CFDictionary?
        guard SecCodeCopySigningInformation(code, SecCSFlags(rawValue: kSecCSSigningInformation), &info) == errSecSuccess,
              let dict = info as? [String: Any],
              let ents = dict["entitlements-dict"] as? [String: Any] else { return false }
        return (ents["get-task-allow"] as? Bool) == true
    }
}
