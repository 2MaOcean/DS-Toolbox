import Foundation
import UIKit

struct EnvironmentReport {
    let iosVersion: String
    let chip: ChipFamily
    let sandboxLevel: SandboxService.AccessLevel
    let isJailbroken: Bool
    let isTrollStore: Bool
    let hasOffset: Bool
    let versionSupported: Bool
    let chipSupported: Bool
    let canFullFileAccess: Bool
    let canElevate: Bool
    let blockedReason: String?
}

final class EnvironmentGuard {
    static let shared = EnvironmentGuard()
    private init() {}

    func check() -> EnvironmentReport {
        let cap = CapabilityDetector.shared
        let sand = SandboxService.shared
        let engine = ExploitEngine.shared
        let excluded = cap.chipFamily == .m5 || cap.chipFamily == .a19 || cap.chipFamily == .a19Pro
        let hasOffset = OffsetDatabase.shared.offsetsFor(
            iosVersion: cap.iosVersion, chip: cap.chipFamily
        ) != nil
        let canFull = sand.canAccessSystemFiles
        let canElevate = !excluded && cap.isChipSupported

        var reason: String?
        if excluded {
            reason = "M5/A19 受 MIE 硬件保护"
        } else if !cap.isVersionSupported {
            reason = "iOS \(cap.iosVersion) 不在支持列表"
        } else if !hasOffset {
            reason = "缺少偏移量"
        } else if sand.level == .sandboxed && !engine.isTrollStore && !engine.isJailbroken {
            reason = "沙盒环境，功能受限"
        }

        return EnvironmentReport(
            iosVersion: cap.iosVersion,
            chip: cap.chipFamily,
            sandboxLevel: sand.level,
            isJailbroken: engine.isJailbroken,
            isTrollStore: engine.isTrollStore,
            hasOffset: hasOffset,
            versionSupported: cap.isVersionSupported,
            chipSupported: cap.isChipSupported,
            canFullFileAccess: canFull,
            canElevate: canElevate,
            blockedReason: reason
        )
    }

    var shouldPromptBeforeInstall: Bool {
        let r = check()
        return !r.isJailbroken && !r.isTrollStore
    }
}
