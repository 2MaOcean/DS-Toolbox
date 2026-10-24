import Foundation
import WebKit

extension BrowserSession {
    func recordVisit(title: String, url: String) {
        guard !url.isEmpty else { return }
        BrowserHistoryStore.shared.record(title: title, url: url)
    }
    func toggleBookmark(title: String, url: String) {
        guard !url.isEmpty else { return }
        if let existing = BookmarkStore.shared.bookmarks.first(where: { $0.url == url }) {
            BookmarkStore.shared.remove(id: existing.id)
        } else {
            BookmarkStore.shared.add(title: title, url: url)
        }
    }
}
