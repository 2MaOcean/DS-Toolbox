import Foundation
struct TelecomAdapter: CloudDriveAdapter {
    let kind: DriveKind = .telecom
    var loginURL: URL { URL(string: "https://cloud.189.cn/")! }
    var requiredCookieNames: [String] { ["COOKIE_LOGIN_USER"] }
    func canHandle(_ url: URL) -> Bool {
        guard let h = url.host?.lowercased() else { return false }
        return h == "cloud.189.cn" || h.hasSuffix(".189.cn")
    }
    func resolve(_ url: URL, credential: DriveCredential) async throws -> ResolvedLink { throw ResolveError.notImplemented }
}
