import Foundation

struct CleanableItem: Identifiable {
    let id: String
    let title: String
    let detail: String
    let sizeBytes: Int64
    let isDefaultSelected: Bool
    let paths: [URL]
}

final class GarbageCleaner {
    static let shared = GarbageCleaner()
    private init() {}

    func scan() async -> [CleanableItem] {
        var items: [CleanableItem] = []
        let fm = FileManager.default
        let cache = fm.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let tmp = fm.temporaryDirectory

        let cacheSize = dirSize(cache)
        if cacheSize > 0 {
            items.append(CleanableItem(
                id: "cache", title: "App 缓存",
                detail: "临时文件与下载缓存",
                sizeBytes: cacheSize, isDefaultSelected: true,
                paths: [cache]
            ))
        }

        let tmpSize = dirSize(tmp)
        if tmpSize > 0 {
            items.append(CleanableItem(
                id: "tmp", title: "系统临时",
                detail: "运行过程产生的临时文件",
                sizeBytes: tmpSize, isDefaultSelected: true,
                paths: [tmp]
            ))
        }

        let dsCache = cache.appendingPathComponent("DSToolbox")
        let dsSize = dirSize(dsCache)
        if dsSize > 0 {
            items.append(CleanableItem(
                id: "dscache", title: "DS 缓存",
                detail: "分片、任务状态等",
                sizeBytes: dsSize, isDefaultSelected: false,
                paths: [dsCache]
            ))
        }
        return items
    }

    func clean(items: [CleanableItem]) async -> Int {
        var freed: Int64 = 0
        let fm = FileManager.default
        for item in items {
            for path in item.paths {
                if let size = try? path.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    freed += Int64(size)
                }
                if let contents = try? fm.contentsOfDirectory(at: path, includingPropertiesForKeys: [.fileSizeKey]) {
                    for entry in contents {
                        let s = (try? entry.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                        try? fm.removeItem(at: entry)
                        freed += Int64(s)
                    }
                }
            }
        }
        return Int(freed)
    }

    private func dirSize(_ url: URL) -> Int64 {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var total: Int64 = 0
        for case let f as URL in enumerator {
            let s = (try? f.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            total += Int64(s)
        }
        return total
    }
}
