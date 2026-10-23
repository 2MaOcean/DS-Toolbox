import Foundation

final class KernelcacheService {
    static let shared = KernelcacheService()
    private init() {}
    var cacheDirectory: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("DSToolbox/Kernelcache")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true); return dir
    }
    var hasCache: Bool { ((try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)) ?? []).isEmpty == false }
    var cacheSize: Int64 { ((try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])) ?? []).reduce(0) { $0 + Int64((try? $1.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0) } }
    func deleteCache() throws {
        let items = (try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)) ?? []
        for item in items { try FileManager.default.removeItem(at: item) }
    }
}
