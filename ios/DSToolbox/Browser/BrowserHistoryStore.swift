import Foundation
import Combine

struct HistoryEntry: Codable, Identifiable, Hashable {
    var id = UUID()
    var title: String
    var url: String
    var visitedAt: Date
}

@MainActor
final class BrowserHistoryStore: ObservableObject {
    static let shared = BrowserHistoryStore()
    @Published private(set) var entries: [HistoryEntry] = []
    private let key = "ds.browser.history"
    private init() { load() }

    func record(title: String, url: String) {
        let t = title.isEmpty ? url : title
        entries.insert(HistoryEntry(title: t, url: url, visitedAt: Date()), at: 0)
        if entries.count > 500 { entries = Array(entries.prefix(500)) }
        persist()
    }
    func clear() { entries.removeAll(); persist() }
    func remove(at offsets: IndexSet) { entries.remove(atOffsets: offsets); persist() }

    private func load() {
        if let d = UserDefaults.standard.data(forKey: key), let list = try? JSONDecoder().decode([HistoryEntry].self, from: d) {
            entries = list
        }
    }
    private func persist() {
        if let d = try? JSONEncoder().encode(entries) { UserDefaults.standard.set(d, forKey: key) }
    }
}
