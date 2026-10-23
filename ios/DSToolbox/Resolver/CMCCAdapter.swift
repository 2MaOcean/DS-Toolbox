import Foundation
struct CMCCAdapter: CloudDriveAdapter {
    let kind: DriveKind = .cmcc
    var loginURL: URL { URL(string: "https://yun.139.com/")! }
    var requiredCookieNames: [String] { ["token"] }
    func canHandle(_ url: URL) -> Bool {
        guard let h = url.host?.lowercased() else { return false }
        return h == "yun.139.com" || h.hasSuffix(".139.com")
    }
    func resolve(_ url: URL, credential: DriveCredential) async throws -> ResolvedLink { throw ResolveError.notImplemented }
}
