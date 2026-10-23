import Foundation
struct QuarkAdapter: CloudDriveAdapter {
    let kind: DriveKind = .quark
    var loginURL: URL { URL(string: "https://pan.quark.cn/")! }
    var requiredCookieNames: [String] { ["__pus"] }
    func canHandle(_ url: URL) -> Bool {
        guard let h = url.host?.lowercased() else { return false }
        return h == "pan.quark.cn" || h.hasSuffix(".quark.cn")
    }
    func resolve(_ url: URL, credential: DriveCredential) async throws -> ResolvedLink { throw ResolveError.notImplemented }
}
