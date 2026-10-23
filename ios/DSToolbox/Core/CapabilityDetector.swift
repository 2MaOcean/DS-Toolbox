import Foundation
import UIKit

enum DeviceCapability: String {
    case unknown, sandboxed, trollStore, jailbroken, kernelExploitable
    var displayName: String {
        switch self {
        case .unknown: return "检测中"
        case .sandboxed: return "沙盒内"
        case .trollStore: return "TrollStore"
        case .jailbroken: return "越狱环境"
        case .kernelExploitable: return "内核可用"
        }
    }
}

enum ChipFamily: String {
    case a15, a16, a17Pro, a18, a18Pro, m1, m2, m3, m4, m5, a19, a19Pro
    case unknown = "Unknown"
    var blockedByMIE: Bool {
        switch self {
        case .m5, .a19, .a19Pro: return true
        default: return false
        }
    }
}

final class CapabilityDetector {
    static let shared = CapabilityDetector()
    private(set) var capability: DeviceCapability = .unknown
    private(set) var iosVersion: String = ""
    private(set) var chipFamily: ChipFamily = .unknown
    private(set) var trollStoreVersion: String?
    private init() {}

    func refresh() {
        iosVersion = UIDevice.current.systemVersion
        chipFamily = detectChip()
        trollStoreVersion = detectTrollStore()
        capability = detectCapability()
    }

    var isVersionSupported: Bool {
        let parts = iosVersion.split(separator: ".").compactMap { Int($0) }
        guard let major = parts.first else { return false }
        let minor = parts.count > 1 ? parts[1] : 0
        let patch = parts.count > 2 ? parts[2] : 0
        switch major {
        case 17: return true
        case 18:
            if minor < 7 { return true }
            if minor == 7 { return patch <= 1 }
            return false
        case 26: return minor == 0
        default: return false
        }
    }

    var isChipSupported: Bool { !chipFamily.blockedByMIE && chipFamily != .unknown }
    var canForceAttempt: Bool { !chipFamily.blockedByMIE && chipFamily != .unknown }

    private func detectCapability() -> DeviceCapability {
        if FileManager.default.fileExists(atPath: "/var/jb") { return .jailbroken }
        if trollStoreVersion != nil { return .trollStore }
        if isVersionSupported && isChipSupported { return .kernelExploitable }
        return .sandboxed
    }

    private func detectTrollStore() -> String? {
        let paths = ["/var/containers/Bundle/Application/.trollstore", "/var/mobile/Library/Preferences/com.opa334.trollstore.plist"]
        for p in paths where FileManager.default.fileExists(atPath: p) { return "已安装" }
        if let url = URL(string: "apple-magnifier://"), UIApplication.shared.canOpenURL(url) { return "已安装" }
        return nil
    }

    private func detectChip() -> ChipFamily {
        var sysInfo = utsname(); uname(&sysInfo)
        let machine = withUnsafePointer(to: &sysInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
        }
        switch machine {
        case "iPhone14,4", "iPhone14,5", "iPhone14,7", "iPhone14,8": return .a15
        case "iPhone15,2", "iPhone15,3", "iPhone15,4", "iPhone15,5": return .a16
        case "iPhone16,1", "iPhone16,2": return .a17Pro
        case "iPhone17,1", "iPhone17,2": return .a18Pro
        case "iPhone17,3", "iPhone17,4": return .a18
        case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11": return .m1
        case "iPad14,3", "iPad14,4", "iPad14,5", "iPad14,6": return .m2
        case "iPad16,3", "iPad16,4", "iPad16,5", "iPad16,6": return .m3
        case "iPad16,8", "iPad16,9": return .m4
        default: return .unknown
        }
    }
}
