import Foundation
enum FileOperationsError: LocalizedError {
    case invalidName, exists, copyFailed(String)
    var errorDescription: String? {
        switch self {
        case .invalidName: return "文件名无效"; case .exists: return "同名文件已存在"; case .copyFailed(let s): return "复制失败：\(s)"
        }
    }
}
enum FileOperations {
    static func rename(_ url: URL, to newName: String) throws -> URL {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw FileOperationsError.invalidName }
        let dest = url.deletingLastPathComponent().appendingPathComponent(trimmed)
        if dest.path == url.path { return url }
        guard !FileManager.default.fileExists(atPath: dest.path) else { throw FileOperationsError.exists }
        try FileManager.default.moveItem(at: url, to: dest); return dest
    }
    static func createFolder(in dir: URL, named name: String) throws -> URL {
        let dest = dir.appendingPathComponent(name.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !FileManager.default.fileExists(atPath: dest.path) else { throw FileOperationsError.exists }
        try FileManager.default.createDirectory(at: dest, withIntermediateDirectories: false); return dest
    }
    static func copy(_ sources: [URL], to directory: URL) throws -> [URL] {
        var created: [URL] = []; let fm = FileManager.default
        for src in sources {
            let base = src.lastPathComponent; let ext = (base as NSString).pathExtension; let name = (base as NSString).deletingPathExtension
            var dest = directory.appendingPathComponent(base); var i = 1
            while fm.fileExists(atPath: dest.path) { dest = directory.appendingPathComponent(ext.isEmpty ? "\(name) (\(i))" : "\(name) (\(i)).\(ext)"); i += 1 }
            do { try fm.copyItem(at: src, to: dest); created.append(dest) } catch { throw FileOperationsError.copyFailed(error.localizedDescription) }
        }
        return created
    }
}
