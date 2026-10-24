import Foundation
import Combine

struct Bookmark: Codable, Identifiable, Hashable {
    var id = UUID()
    var title: String
    var url: String
}

@MainActor
final class BookmarkStore: ObservableObject {
    static let shared = BookmarkStore()
    @Published private(set) var bookmarks: [Bookmark] = []
    private let key = "ds.bookmarks"
    private init() { load() }

    func add(title: String, url: String) {
        let t = title.isEmpty ? url : title
        bookmarks.append(Bookmark(title: t, url: url))
        persist()
    }
    func remove(at offsets: IndexSet) { bookmarks.remove(atOffsets: offsets); persist() }
    func remove(id: UUID) { bookmarks.removeAll { $0.id == id }; persist() }
    func contains(url: String) -> Bool { bookmarks.contains { $0.url == url } }

    private func load() {
        if let d = UserDefaults.standard.data(forKey: key), let list = try? JSONDecoder().decode([Bookmark].self, from: d) {
            bookmarks = list
        }
    }
    private func persist() {
        if let d = try? JSONEncoder().encode(bookmarks) { UserDefaults.standard.set(d, forKey: key) }
    }
}
