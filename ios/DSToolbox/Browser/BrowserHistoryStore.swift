import Foundation
import Combine
struct HistoryEntry: Codable, Identifiable { var id = UUID(); var title: String; var url: String; var visitedAt: Date }
final class BrowserHistoryStore: ObservableObject {
    static let shared = BrowserHistoryStore(); @Published private(set) var entries: [HistoryEntry] = []; private let key = "browser.history"
    private init() { if let d = UserDefaults.standard.data(forKey: key), let l = try? JSONDecoder().decode([HistoryEntry].self, from: d) { entries = l } }
    func record(title: String, url: String) { guard !url.isEmpty else { return }; entries.insert(HistoryEntry(title: title, url: url, visitedAt: Date()), at: 0); if entries.count > 500 { entries = Array(entries.prefix(500)) }; save() }
    func clear() { entries.removeAll(); save() }
    private func save() { if let d = try? JSONEncoder().encode(entries) { UserDefaults.standard.set(d, forKey: key) } }
}
