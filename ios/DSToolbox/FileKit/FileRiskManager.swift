import Foundation

enum FileRiskLevel: String, CaseIterable {
    case low = "低风险"
    case medium = "中风险"
    case high = "高风险"
}

struct FileRiskManager {
    static let shared = FileRiskManager()
    
    func level(for url: URL) -> FileRiskLevel {
        let path = url.path.lowercased()
        if FileSorter.isDirectory(url) {
            if path.contains("/system") || path.contains("/library") || path.contains("/var/jb") || path.contains("/private/var") || path.contains("/applications") {
                return .high
            }
            return .low
        }
        let ext = url.pathExtension.lowercased()
        if ["plist", "sh", "dylib", "deb", "mobileprovision", "car"].contains(ext) { return .high }
        if ["json", "xml", "yaml", "yml", "csv", "html", "js", "css"].contains(ext) { return .medium }
        return .low
    }
    
    var backupDir: URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let dir = caches.appendingPathComponent("DSBackups", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    func backup(url: URL) throws {
        let dest = backupDir.appendingPathComponent("\(Int(Date().timeIntervalSince1970))_\(url.lastPathComponent)")
        try FileManager.default.copyItem(at: url, to: dest)
    }
    
    func restore(for url: URL) throws -> URL? {
        let prefix = url.lastPathComponent
        let items = (try? FileManager.default.contentsOfDirectory(at: backupDir, includingPropertiesForKeys: nil)) ?? []
        let filtered = items.filter { $0.lastPathComponent.hasSuffix(prefix) }.sorted { $0.lastPathComponent > $1.lastPathComponent }
        guard let latest = filtered.first else { return nil }
        try? FileManager.default.removeItem(at: url)
        try FileManager.default.copyItem(at: latest, to: url)
        return url
    }
}
