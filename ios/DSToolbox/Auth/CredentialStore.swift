import Foundation
final class CredentialStore {
    static let shared = CredentialStore()
    func save(_ c: DriveCredential) throws { try KeychainStore.save(try JSONEncoder().encode(c), account: c.kind) }
    func load(kind: DriveKind) -> DriveCredential? {
        guard let d = KeychainStore.load(account: kind.rawValue) else { return nil }
        return try? JSONDecoder().decode(DriveCredential.self, from: d)
    }
    func delete(kind: DriveKind) { KeychainStore.delete(account: kind.rawValue) }
}
