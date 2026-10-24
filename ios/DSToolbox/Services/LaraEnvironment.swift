import Foundation
import UIKit

struct LaraEnvironmentInfo {
    let iosVersion: String
    let chip: ChipFamily
    let isSupported: Bool
    let isExcludedChip: Bool
    let isJailbroken: Bool
    let isTrollStore: Bool
    let hasKRW: Bool
    let hasOffsets: Bool
    let blockedReason: String?
}

@MainActor
final class LaraEnvironment: ObservableObject {
    static let shared = LaraEnvironment()
    @Published private(set) var info: LaraEnvironmentInfo?
    private init() {}

    func refresh() {
        let cap = CapabilityDetector.shared
        let excluded = cap.chipFamily == .m5 || cap.chipFamily == .a19 || cap.chipFamily == .a19Pro
        let supported = cap.isVersionSupported && !excluded
        let krw = DarkSwordKRW.shared
        let off = KernelcacheAutoResolver.shared.offsets

        var reason: String?
        if excluded { reason = "M5/A19 受 MIE/MTE 硬件保护" }
        else if !cap.isVersionSupported { reason = "iOS \(cap.iosVersion) 不在支持列表" }
        else if off == nil { reason = "缺少偏移量，请下载 kernelcache" }
        else if !krw.isReady && !TrollStoreBridge.shared.isInstalled {
            reason = "沙盒环境，需 TrollStore 或越狱"
        }

        info = LaraEnvironmentInfo(
            iosVersion: cap.iosVersion, chip: cap.chipFamily,
            isSupported: supported, isExcludedChip: excluded,
            isJailbroken: FileManager.default.fileExists(atPath: "/var/jb"),
            isTrollStore: TrollStoreBridge.shared.isInstalled,
            hasKRW: krw.isReady, hasOffsets: off != nil,
            blockedReason: reason
        )
    }
}
