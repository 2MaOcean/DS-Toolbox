import Foundation
import Combine

struct ManagedApp: Identifiable {
    let id: String
    let name: String
    let bundleID: String
    let bundlePath: String
    let dataPath: String
    let sizeBytes: Int64
    let cacheSize: Int64
}

@MainActor
final class AppManagement: ObservableObject {
    static let shared = AppManagement()
    @Published private(set) var apps: [ManagedApp] = []
    @Published private(set) var status = "未扫描"
    private init() {}

    func scan() {
        let installed = AppScanner.shared.scanAllApps()
        apps = installed.map { a in
            let data = a.bundlePath
                .replacingOccurrences(of: "/Bundle/Application/", with: "/Data/Application/")
            let size = Self.dirSize(a.bundlePath)
            let cache = Self.dirSize((data as NSString).appendingPathComponent("Library/Caches"))
            return ManagedApp(
                id: a.bundleID, name: a.displayName, bundleID: a.bundleID,
                bundlePath: a.bundlePath, dataPath: data,
                sizeBytes: size, cacheSize: cache
            )
        }
        status = "找到 \(apps.count) 个应用"
    }

    func clearCache(_ app: ManagedApp) -> Bool {
        let paths = [
            (app.dataPath as NSString).appendingPathComponent("Library/Caches"),
            (app.dataPath as NSString).appendingPathComponent("tmp")
        ]
        var ok = false
        for p in paths {
            if (try? FileManager.default.removeItem(atPath: p)) != nil { ok = true }
        }
        status = ok ? "已清理 \(app.name) 缓存" : "清理失败"
        return ok
    }

    func uninstall(_ app: ManagedApp) -> Bool {
        guard SandboxService.shared.level == .root else {
            status = "需越狱环境"; return false
        }
        if (try? FileManager.default.removeItem(atPath: app.bundlePath)) != nil {
            status = "已卸载 \(app.name)，重启生效"
            return true
        }
        status = "卸载失败"
        return false
    }

    private static func dirSize(_ path: String) -> Int64 {
        guard let e = FileManager.default.enumerator(atPath: path) else { return 0 }
        var total: Int64 = 0
        for case let f as String in e {
            let full = (path as NSString).appendingPathComponent(f)
            let s = (try? FileManager.default.attributesOfItem(atPath: full)[.size] as? Int64) ?? 0
            total += s
        }
        return total
    }
}
