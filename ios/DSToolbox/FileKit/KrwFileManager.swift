import Foundation
import Combine

@MainActor
final class KrwFileManager: ObservableObject {
    static let shared = KrwFileManager()
    @Published private(set) var status = "未连接"
    private init() {}

    var isReady: Bool { CapabilityGate.shared.canUseKRWFiles }

    func list(_ path: String) -> [URL] {
        if let items = try? FileManager.default.contentsOfDirectory(atPath: path) {
            return items.map { URL(fileURLWithPath: (path as NSString).appendingPathComponent($0)) }
        }
        return []
    }

    func read(_ path: String) -> Data? {
        try? Data(contentsOf: URL(fileURLWithPath: path))
    }

    func write(_ path: String, data: Data) -> Bool {
        do {
            try data.write(to: URL(fileURLWithPath: path), options: .atomic)
            status = "已写入 \(path)"
            return true
        } catch {
            status = "写入失败：\(error.localizedDescription)"
            return false
        }
    }

    func remove(_ path: String) -> Bool {
        do {
            try FileManager.default.removeItem(atPath: path)
            return true
        } catch {
            status = error.localizedDescription
            return false
        }
    }

    var accessRoots: [RootEntry] {
        var roots = SandboxService.shared.allowedRoots
        if isReady {
            roots.append(RootEntry(label: "/var", path: "/var"))
            roots.append(RootEntry(label: "/private", path: "/private"))
        }
        if FileManager.default.fileExists(atPath: "/var/jb") {
            roots.append(RootEntry(label: "/", path: "/"))
        }
        return roots
    }
}
