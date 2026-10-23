import Foundation
struct GuangyaAdapter: CloudDriveAdapter {
    let kind: DriveKind = .guangya
    var loginURL: URL { URL(string: "https://www.guangyapan.com/")! }
    var requiredCookieNames: [String] { ["token"] }
    func canHandle(_ url: URL) -> Bool {
        guard let h = url.host?.lowercased() else { return false }
        return h.contains("guangya") || h.contains("guangyapan")
    }
    func resolve(_ url: URL, credential: DriveCredential) async throws -> ResolvedLink { throw ResolveError.notImplemented }
}
