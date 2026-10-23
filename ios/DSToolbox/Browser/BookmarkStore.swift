import Foundation
import Combine
struct Bookmark: Codable, Identifiable { var id = UUID(); var title: String; var url: String; var addedAt: Date }
final class BookmarkStore: ObservableObject {
    static let shared = BookmarkStore(); @Published private(set) var bookmarks: [Bookmark] = []; private let key = "browser.bookmarks"
    private init() { if let d = UserDefaults.standard.data(forKey: key), let l = try? JSONDecoder().decode([Bookmark].self, from: d) { bookmarks = l } }
    func add(title: String, url: String) { bookmarks.insert(Bookmark(title: title, url: url, addedAt: Date()), at: 0); save() }
    func remove(_ id: UUID) { bookmarks.removeAll { $0.id == id }; save() }
    private func save() { if let d = try? JSONEncoder().encode(bookmarks) { UserDefaults.standard.set(d, forKey: key) } }
}
