import Foundation
enum DownloadPaths {
    static func downloadsDirectory() throws -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Downloads")
        if !FileManager.default.fileExists(atPath: dir.path) { try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true) }
        return dir
    }
    static var downloadsDirectoryPath: String { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Downloads").path }
    static func uniqueDestination(in directory: URL, fileName: String) throws -> URL {
        if !FileManager.default.fileExists(atPath: directory.path) { try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true) }
        let base = (fileName as NSString).deletingPathExtension; let ext = (fileName as NSString).pathExtension
        var candidate = directory.appendingPathComponent(fileName); var i = 1
        while FileManager.default.fileExists(atPath: candidate.path) { candidate = directory.appendingPathComponent(ext.isEmpty ? "\(base) (\(i))" : "\(base) (\(i)).\(ext)"); i += 1 }
        return candidate
    }
    static func taskDirectory(for id: UUID) -> URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("DSToolbox").appendingPathComponent(id.uuidString)
    }
    static func cacheSize(except ids: Set<UUID> = []) -> Int64 {
        let root = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("DSToolbox")
        guard let items = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var total: Int64 = 0; let skip = Set(ids.map(\.uuidString))
        for item in items {
            if skip.contains(item.lastPathComponent) { continue }
            if let en = FileManager.default.enumerator(at: item, includingPropertiesForKeys: [.fileSizeKey]) {
                for case let f as URL in en { if let size = (try? f.resourceValues(forKeys: [.fileSizeKey]))?.fileSize { total += Int64(size) } }
            }
        }
        return total
    }
    static func clearCache(except ids: Set<UUID>) throws {
        let root = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("DSToolbox")
        guard let items = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else { return }
        let skip = Set(ids.map(\.uuidString))
        for item in items { if skip.contains(item.lastPathComponent) { continue }; try? FileManager.default.removeItem(at: item) }
    }
}
