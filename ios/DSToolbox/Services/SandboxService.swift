import Foundation

final class SandboxService {
    static let shared = SandboxService()
    enum AccessLevel: String { case sandboxed = "沙盒内", mobileUser = "mobile", root = "root" }
    private(set) var level: AccessLevel = .sandboxed
    private init() {}

    func detectLevel() {
        if FileManager.default.fileExists(atPath: "/var/jb") {
            level = .root; return
        }
        if FileManager.default.fileExists(atPath: "/var/containers/Bundle/Application/.trollstore") {
            level = .mobileUser; return
        }
        let path = "/var/mobile/Containers/Data/Application"
        level = (try? FileManager.default.contentsOfDirectory(atPath: path)) != nil ? .mobileUser : .sandboxed
    }

    var entitlementSummary: String {
        switch level {
        case .sandboxed: return "无 no-sandbox（普通 App）"
        case .mobileUser: return "mobile 用户可访问"
        case .root: return "root / 越狱环境"
        }
    }

    var canAccessSystemFiles: Bool { level != .sandboxed }
    var canWriteSystemFiles: Bool { level == .root }

    var allowedRoots: [RootEntry] {
        var roots = [
            RootEntry(label: "Downloads", path: DownloadPaths.downloadsDirectoryPath),
            RootEntry(label: "Documents", path: NSHomeDirectory() + "/Documents")
        ]
        if level != .sandboxed {
            roots.append(RootEntry(label: "/var/mobile", path: "/var/mobile"))
            roots.append(RootEntry(label: "/var/containers", path: "/var/containers"))
        }
        if level == .root {
            roots.append(RootEntry(label: "/", path: "/"))
        }
        return roots
    }
}

struct RootEntry: Identifiable, Hashable {
    let id = UUID()
    let label: String
    let path: String
    var url: URL { URL(fileURLWithPath: path) }
    static func == (lhs: RootEntry, rhs: RootEntry) -> Bool { lhs.path == rhs.path }
    func hash(into hasher: inout Hasher) { hasher.combine(path) }
}
