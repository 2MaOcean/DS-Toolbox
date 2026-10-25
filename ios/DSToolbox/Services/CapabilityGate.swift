import Foundation
import Security
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
        let isJailbroken = FileManager.default.fileExists(atPath: "/var/jb")
        let hasGetTaskAllow = Self.hasGetTaskAllow()
        canUseKRWFiles = (canUseDarkSword || isJailbroken) && !isEnterprise
        canManageProcesses = (hasGetTaskAllow || canUseTrollStore || isJailbroken) && !isEnterprise
        canUseAdvanced = !isEnterprise && !isAppStore
    }

    private static func hasGetTaskAllow() -> Bool {
        // iOS SDK 不含 macOS-only 的 SecStaticCode/SecCodeCopySigningInformation。
        // 退化为读 embedded.mobileprovision：含 ProvisionedDevices 即开发者签名（get-task-allow=true）。
        // 越狱 / TrollStore 场景由 refresh() 里其它条件兜底。
        guard let path = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return false }
        let s = String(decoding: data, as: UTF8.self)
        return s.contains("ProvisionedDevices")
    }
}
