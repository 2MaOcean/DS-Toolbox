import Foundation

struct CMCCAdapter: CloudDriveAdapter, CookieResolvableAdapter {
    let kind: DriveKind = .cmcc
    var loginURL: URL { URL(string: "https://yun.139.com/")! }
    var requiredCookieNames: [String] { ["token"] }
    var apiBase: String { "https://yun.139.com" }

    func canHandle(_ url: URL) -> Bool {
        (url.host?.lowercased() ?? "").hasSuffix(".139.com")
    }

    func resolve(_ url: URL, credential: DriveCredential) async throws -> ResolvedLink {
        try await resolveTemplate(url, cred: credential,
                                  path: "/orchestration/personalCloud/outlink/v2/getOutLink",
                                  params: ["url": url.absoluteString])
    }

    func extractDirectLink(from json: [String: Any]) -> String? {
        if let d = json["data"] as? [String: Any] { return d["cdnUrl"] as? String }
        return nil
    }
    func extractFileName(from json: [String: Any]) -> String? {
        if let d = json["data"] as? [String: Any] { return d["fileName"] as? String }
        return nil
    }
}
