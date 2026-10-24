import Foundation

struct InstalledApp: Identifiable, Hashable {
    let id: String
    let bundleID: String
    let displayName: String
    let version: String
    let bundlePath: String
    let isSystem: Bool
}

final class AppScanner {
    static let shared = AppScanner()
    func scanAllApps() -> [InstalledApp] {
        // 占位：真实设备需通过 LSApplicationWorkspace 或私有 API 获取
        return []
    }
}
