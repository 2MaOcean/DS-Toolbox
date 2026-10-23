import Foundation
struct BaiduAdapter: CloudDriveAdapter {
    let kind: DriveKind = .baidu
    var loginURL: URL { URL(string: "https://pan.baidu.com/")! }
    var requiredCookieNames: [String] { ["BDUSS"] }
    func canHandle(_ url: URL) -> Bool {
        guard let h = url.host?.lowercased() else { return false }
        return h == "pan.baidu.com" || h.hasSuffix(".baidu.com")
    }
    func resolve(_ url: URL, credential: DriveCredential) async throws -> ResolvedLink { throw ResolveError.notImplemented }
}
