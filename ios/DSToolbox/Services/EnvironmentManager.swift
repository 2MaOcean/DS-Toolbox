import Foundation
import UIKit

struct EnvironmentInfo {
    let iosVersion: String
    let chip: ChipFamily
    let isSupported: Bool
    let isExcludedChip: Bool
    let sandboxLevel: SandboxService.AccessLevel
    let isJailbroken: Bool
    let isTrollStore: Bool
    let hasKernelcache: Bool
    let hasOffsets: Bool
    let blockedReason: String?
}

@MainActor
final class EnvironmentManager: ObservableObject {
    static let shared = EnvironmentManager()
    @Published private(set) var info: EnvironmentInfo?
    @Published private(set) var offsets: KernelOffsets?
    private init() {}

    func refresh() {
        let cap = CapabilityDetector.shared
        let sand = SandboxService.shared
        let excluded = cap.chipFamily == .m5 || cap.chipFamily == .a19 || cap.chipFamily == .a19Pro
        let supported = cap.isVersionSupported && !excluded
        let kc = KernelcacheManager.shared
        let off = kc.offsets

        var reason: String?
        if excluded { reason = "M5/A19 受 MIE/MTE 硬件保护，无法利用" }
        else if !cap.isVersionSupported { reason = "iOS \(cap.iosVersion) 不在支持列表" }
        else if off == nil { reason = "缺少偏移量，请下载 kernelcache" }
        else if sand.level == .sandboxed && !TrollStoreService.shared.isInstalled {
            reason = "沙盒环境，需 TrollStore 或越狱才能完整利用"
        }

        info = EnvironmentInfo(
            iosVersion: cap.iosVersion,
            chip: cap.chipFamily,
            isSupported: supported,
            isExcludedChip: excluded,
            sandboxLevel: sand.level,
            isJailbroken: ExploitEngine.shared.isJailbroken,
            isTrollStore: TrollStoreService.shared.isInstalled,
            hasKernelcache: kc.isReady,
            hasOffsets: off != nil,
            blockedReason: reason
        )
    }

    func modifyOffsets(t1szBoot: UInt64) {
        guard var o = offsets else { return }
        o = KernelOffsets(
            iosVersion: o.iosVersion, chip: o.chip,
            kernelBase: o.kernelBase, t1szBoot: t1szBoot,
            offsetIcmp6Filt: o.offsetIcmp6Filt,
            offsetSoProto: o.offsetSoProto,
            offsetPrInput: o.offsetPrInput
        )
        offsets = o
    }
}
