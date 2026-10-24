import Foundation

struct CleanableItem: Identifiable {
    let id: String
    let title: String
    let detail: String
    let sizeBytes: Int64
    let isDefaultSelected: Bool
}

final class GarbageCleaner {
    static let shared = GarbageCleaner()
    private init() {}
    
    func scan() async -> [CleanableItem] {
        // 占位：实际可扫描 Caches 目录
        return [CleanableItem(id: "cache", title: "临时缓存", detail: "App 产生的临时文件", sizeBytes: 1024 * 1024, isDefaultSelected: true)]
    }
    
    func clean(items: [CleanableItem]) async -> Int {
        return 0 // 返回清理的文件数
    }
}
