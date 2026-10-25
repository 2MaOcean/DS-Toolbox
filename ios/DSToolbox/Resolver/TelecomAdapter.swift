import Foundation

struct TelecomAdapter: CloudDriveAdapter, CookieResolvableAdapter {
    let kind: DriveKind = .telecom
    var loginURL: URL { URL(string: "https://cloud.189.cn/")! }
    var requiredCookieNames: [String] { ["COOKIE_LOGIN_USER"] }
    var apiBase: String { "https://cloud.189.cn" }

    func canHandle(_ url: URL) -> Bool {
        (url.host?.lowercased() ?? "").hasSuffix(".189.cn")
    }

    func resolve(_ url: URL, credential: DriveCredential) async throws -> ResolvedLink {
        try await resolveTemplate(url, cred: credential,
                                  path: "/api/open/file/getFileDownloadUrl.action",
                                  params: ["url": url.absoluteString])
    }

    func extractDirectLink(from json: [String: Any]) -> String? { json["fileDownloadUrl"] as? String }
    func extractFileName(from json: [String: Any]) -> String? { json["fileName"] as? String }
}
