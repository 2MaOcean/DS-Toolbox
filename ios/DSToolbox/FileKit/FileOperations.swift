import Foundation

enum FileOperationsError: LocalizedError {
    case exists, invalidContent
    var errorDescription: String? {
        switch self {
        case .exists: return "同名文件已存在"
        case .invalidContent: return "内容格式无效"
        }
    }
}

enum FileOperations {
    static func rename(_ url: URL, to newName: String) throws -> URL {
        let dest = url.deletingLastPathComponent().appendingPathComponent(newName)
        guard !FileManager.default.fileExists(atPath: dest.path) else { throw FileOperationsError.exists }
        try FileManager.default.moveItem(at: url, to: dest)
        return dest
    }
    static func createFolder(in dir: URL, named name: String) throws -> URL {
        let dest = dir.appendingPathComponent(name)
        guard !FileManager.default.fileExists(atPath: dest.path) else { throw FileOperationsError.exists }
        try FileManager.default.createDirectory(at: dest, withIntermediateDirectories: false)
        return dest
    }
    static func createPlist(in dir: URL, named name: String, content: [String: Any]) throws -> URL {
        let data = try PropertyListSerialization.data(fromPropertyList: content, format: .xml, options: 0)
        return try writeNew(in: dir, named: name.hasSuffix(".plist") ? name : "\(name).plist", data: data)
    }
    static func createXML(in dir: URL, named name: String, content: String) throws -> URL {
        guard let data = content.data(using: .utf8) else { throw FileOperationsError.invalidContent }
        return try writeNew(in: dir, named: name.hasSuffix(".xml") ? name : "\(name).xml", data: data)
    }
    static func createJSON(in dir: URL, named name: String, content: String) throws -> URL {
        guard let data = content.data(using: .utf8),
              (try? JSONSerialization.jsonObject(with: data)) != nil else { throw FileOperationsError.invalidContent }
        return try writeNew(in: dir, named: name.hasSuffix(".json") ? name : "\(name).json", data: data)
    }
    private static func writeNew(in dir: URL, named name: String, data: Data) throws -> URL {
        let dest = dir.appendingPathComponent(name)
        guard !FileManager.default.fileExists(atPath: dest.path) else { throw FileOperationsError.exists }
        try data.write(to: dest, options: .atomic)
        return dest
    }
}
