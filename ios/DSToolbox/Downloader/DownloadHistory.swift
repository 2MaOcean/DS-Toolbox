import Foundation
import Combine

struct HistoryRecord: Codable, Identifiable {
    let id: UUID
    var fileName: String
    var size: Int64
    var completedAt: Date
    var kind: String
    var urlString: String
}

@MainActor
final class DownloadHistory: ObservableObject {
    static let shared = DownloadHistory()
    @Published private(set) var records: [HistoryRecord] = []
    private init() { load() }
    func append(_ r: HistoryRecord) { records.insert(r, at: 0); if records.count > 200 { records = Array(records.prefix(200)) }; save() }
    func clear() { records.removeAll(); save() }
    private func file() -> URL? {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("DSToolbox")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("history.json")
    }
    private func load() { guard let f = file(), let d = try? Data(contentsOf: f) else { return }; records = (try? JSONDecoder().decode([HistoryRecord].self, from: d)) ?? [] }
    private func save() { guard let f = file(), let d = try? JSONEncoder().encode(records) else { return }; try? d.write(to: f, options: .atomic) }
}

final class DownloadTaskOptionsStore {
    static let shared = DownloadTaskOptionsStore()
    private var cache: [UUID: DownloadOptions] = [:]
    func set(_ o: DownloadOptions, for id: UUID) { cache[id] = o }
    func options(for id: UUID) -> DownloadOptions { cache[id] ?? .default }
    func remove(for id: UUID) { cache.removeValue(forKey: id) }
}
