import Foundation

protocol CookieResolvableAdapter: CloudDriveAdapter {
    var apiBase: String { get }
}

extension CookieResolvableAdapter {
    func helper(cred: DriveCredential) -> CloudDriveAPIHelper {
        CloudDriveAPIHelper(
            cookieHeader: cred.cookieHeader,
            userAgent: cred.userAgent,
            referer: loginURL.absoluteString
        )
    }

    func resolveTemplate(_ url: URL, cred: DriveCredential, path: String, params: [String: String]) async throws -> ResolvedLink {
        let helper = helper(cred: cred)
        guard let api = URL(string: apiBase + path) else { throw ResolveError.unsupported }
        let data = try await helper.get(api, extra: params)
        let json = try helper.json(data)
        guard let direct = extractDirectLink(from: json), let directURL = URL(string: direct) else {
            throw ResolveError.notImplemented
        }
        let name = extractFileName(from: json) ?? url.lastPathComponent
        return ResolvedLink(
            url: directURL,
            headers: ["User-Agent": cred.userAgent, "Referer": loginURL.absoluteString],
            fileName: name.isEmpty ? "download.bin" : name,
            expectedSize: nil,
            resolvedAt: Date()
        )
    }

    func extractDirectLink(from json: [String: Any]) -> String? { nil }
    func extractFileName(from json: [String: Any]) -> String? { nil }
}
