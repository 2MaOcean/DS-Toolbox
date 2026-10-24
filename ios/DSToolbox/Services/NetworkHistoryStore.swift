import Foundation
import Combine

struct DNSHistoryEntry: Codable, Identifiable, Hashable {
    var id = UUID()
    var domain: String
    var records: [String]
    var queriedAt: Date
}

@MainActor
final class NetworkHistoryStore: ObservableObject {
    static let shared = NetworkHistoryStore()
    @Published private(set) var entries: [DNSHistoryEntry] = []
    private let key = "ds.network.history"
    private init() { load() }

    func add(domain: String, records: [String]) {
        entries.insert(DNSHistoryEntry(domain: domain, records: records, queriedAt: Date()), at: 0)
        if entries.count > 100 { entries = Array(entries.prefix(100)) }
        persist()
    }
    func clear() { entries.removeAll(); persist() }
    func remove(at offsets: IndexSet) { entries.remove(atOffsets: offsets); persist() }

    private func load() {
        if let d = UserDefaults.standard.data(forKey: key),
           let list = try? JSONDecoder().decode([DNSHistoryEntry].self, from: d) {
            entries = list
        }
    }
    private func persist() {
        if let d = try? JSONEncoder().encode(entries) { UserDefaults.standard.set(d, forKey: key) }
    }
}
