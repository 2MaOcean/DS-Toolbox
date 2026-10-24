import Foundation

enum FileSortOption: String, CaseIterable, Identifiable {
    case nameAsc, nameDesc, sizeAsc, sizeDesc, dateAsc, dateDesc
    var id: String { rawValue }
    var label: String {
        switch self {
        case .nameAsc: return "名称 ↑"
        case .nameDesc: return "名称 ↓"
        case .sizeAsc: return "大小 ↑"
        case .sizeDesc: return "大小 ↓"
        case .dateAsc: return "时间 ↑"
        case .dateDesc: return "时间 ↓"
        }
    }
}

enum FileSorter {
    static func sort(_ files: [URL], by option: FileSortOption) -> [URL] {
        files.sorted { a, b in
            switch option {
            case .nameAsc: return a.lastPathComponent.localizedStandardCompare(b.lastPathComponent) == .orderedAscending
            case .nameDesc: return a.lastPathComponent.localizedStandardCompare(b.lastPathComponent) == .orderedDescending
            case .sizeAsc: return (size(a) ?? 0) < (size(b) ?? 0)
            case .sizeDesc: return (size(a) ?? 0) > (size(b) ?? 0)
            case .dateAsc: return (date(a) ?? .distantPast) < (date(b) ?? .distantPast)
            case .dateDesc: return (date(a) ?? .distantPast) > (date(b) ?? .distantPast)
            }
        }
    }
    static func size(_ url: URL) -> Int64? { (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize.map(Int64.init) }
    static func date(_ url: URL) -> Date? { (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate }
    static func isDirectory(_ url: URL) -> Bool { (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false }
}
