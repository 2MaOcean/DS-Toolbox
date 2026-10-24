import Foundation
import Combine

@MainActor
final class DownloadDestinationService: ObservableObject {
    static let shared = DownloadDestinationService()
    @Published private(set) var currentDirectory: URL
    @Published private(set) var displayName: String
    private let bookmarkKey = "ds.destination.bookmark"

    private init() {
        let fallback = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Downloads")
        var stale = false
        if let data = UserDefaults.standard.data(forKey: bookmarkKey),
           let url = try? URL(resolvingBookmarkData: data, options: [.withoutUI], relativeTo: nil, bookmarkDataIsStale: &stale),
           FileManager.default.isWritableFile(atPath: url.path) {
            _ = url.startAccessingSecurityScopedResource()
            currentDirectory = url; displayName = url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent; return
        }
        currentDirectory = fallback; displayName = "Downloads（沙盒）"
    }
    func setDirectory(_ url: URL) throws {
        _ = url.startAccessingSecurityScopedResource()
        UserDefaults.standard.set(try url.bookmarkData(options: [.minimalBookmark]), forKey: bookmarkKey)
        currentDirectory = url; displayName = url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent
    }
    func resetToSandbox() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        currentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Downloads"); displayName = "Downloads（沙盒）"
    }
    var isExternal: Bool { !currentDirectory.path.hasPrefix(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path) }
}
