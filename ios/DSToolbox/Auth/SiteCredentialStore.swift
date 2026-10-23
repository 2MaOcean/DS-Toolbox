import Foundation
import Combine

struct SiteCredential: Codable, Identifiable {
    var id: String { host }
    let host: String
    let cookieHeader: String
    let userAgent: String
    let savedAt: Date
    var displayName: String
    var isStale: Bool { Date().timeIntervalSince(savedAt) > 30 * 24 * 3600 }
}

final class SiteCredentialStore: ObservableObject {
    static let shared = SiteCredentialStore()
    @Published private(set) var credentials: [SiteCredential] = []
    private let account = "ds.site-credentials"
    private init() { load() }

    func save(host: String, cookieHeader: String, userAgent: String, displayName: String? = nil) {
        guard !host.isEmpty, !cookieHeader.isEmpty else { return }
        let record = SiteCredential(host: host.lowercased(), cookieHeader: cookieHeader, userAgent: userAgent, savedAt: Date(), displayName: displayName ?? host)
        if let idx = credentials.firstIndex(where: { $0.host == record.host }) { credentials[idx] = record }
        else { credentials.append(record) }
        persist()
    }
    func credential(for host: String) -> SiteCredential? {
        let h = host.lowercased()
        return credentials.first { $0.host == h } ?? credentials.first { h.hasSuffix("." + $0.host) }
    }
    func delete(host: String) { credentials.removeAll { $0.host == host.lowercased() }; persist() }
    func deleteAll() { credentials.removeAll(); persist() }
    static func headerFromCookies(_ cookies: [HTTPCookie]) -> String { cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ") }
    private func load() { if let d = KeychainStore.load(account: account), let list = try? JSONDecoder().decode([SiteCredential].self, from: d) { credentials = list } }
    private func persist() { if let d = try? JSONEncoder().encode(credentials) { try? KeychainStore.save(d, account: account) } }
}
