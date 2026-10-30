import Foundation

enum ShellBackend {
    case jailbreak   // /var/jb 存在，有 apt/dpkg/bash
    case trollStore  // TrollStore，有 ldid 等
    case sandbox     // 普通 App，只能走内置实现

    static let current: ShellBackend = detect()

    private static func detect() -> ShellBackend {
        let fm = FileManager.default
        if fm.fileExists(atPath: "/var/jb/usr/bin/bash")
            || fm.fileExists(atPath: "/var/jb/usr/bin/apt")
            || fm.fileExists(atPath: "/var/jb/usr/bin/dpkg") {
            return .jailbreak
        }
        if fm.fileExists(atPath: "/var/containers/Bundle/Application/.trollstore")
            || fm.fileExists(atPath: "/usr/bin/ldid") {
            return .trollStore
        }
        return .sandbox
    }

    var label: String {
        switch self {
        case .jailbreak:  return "越狱 (root)"
        case .trollStore: return "TrollStore"
        case .sandbox:    return "沙盒 (仅内置命令)"
        }
    }

    var canSpawnBinaries: Bool { self != .sandbox }

    static let searchPaths = [
        "/var/jb/usr/bin", "/var/jb/usr/sbin", "/var/jb/bin",
        "/usr/bin", "/bin", "/usr/sbin", "/sbin", "/var/jb/usr/local/bin"
    ]

    static func which(_ name: String) -> String? {
        let fm = FileManager.default
        for dir in searchPaths {
            let p = dir + "/" + name
            if fm.isExecutableFile(atPath: p) { return p }
        }
        return nil
    }
}
