import Foundation
import Combine

@MainActor
final class LaraFileManager: ObservableObject {
    static let shared = LaraFileManager()
    @Published private(set) var status = "未连接"
    private init() {}

    var krwAvailable: Bool { DarkSwordKRW.shared.isReady }
    var rootAvailable: Bool { SandboxService.shared.level == .root }

    func readFile(at path: String) -> Data? {
        try? Data(contentsOf: URL(fileURLWithPath: path))
    }

    func writeFile(at path: String, data: Data) -> Bool {
        do {
            try data.write(to: URL(fileURLWithPath: path), options: .atomic)
            return true
        } catch {
            status = "写入失败：\(error.localizedDescription)"
            return false
        }
    }

    var accessRoots: [RootEntry] {
        var roots = SandboxService.shared.allowedRoots
        if rootAvailable {
            roots.append(RootEntry(label: "/var", path: "/var"))
            roots.append(RootEntry(label: "/private", path: "/private"))
            roots.append(RootEntry(label: "/System", path: "/System"))
        } else if krwAvailable {
            roots.append(RootEntry(label: "/var/mobile", path: "/var/mobile"))
        }
        return roots
    }
}
