import Foundation

struct QuarkAdapter: CloudDriveAdapter, CookieResolvableAdapter {
    let kind: DriveKind = .quark
    var loginURL: URL { URL(string: "https://pan.quark.cn/")! }
    var requiredCookieNames: [String] { ["__pus"] }
    var apiBase: String { "https://drive-pc.quark.cn" }
    var userAgent: String {
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        + "AppleWebKit/537.36 (KHTML, like Gecko) "
        + "Chrome/120.0.0.0 Safari/537.36"
    }

    func canHandle(_ url: URL) -> Bool {
        guard let h = url.host?.lowercased() else { return false }
        return h == "pan.quark.cn" || h.hasSuffix(".quark.cn")
    }

    func resolve(_ url: URL, credential: DriveCredential) async throws -> ResolvedLink {
        try await resolveTemplate(url, cred: credential,
                                  path: "/1/clouddrive/share/sharepage/download",
                                  params: ["pwd_id": url.absoluteString])
    }

    func extractDirectLink(from json: [String: Any]) -> String? {
        if let data = json["data"] as? [String: Any], let u = data["download_url"] as? String { return u }
        return nil
    }
    func extractFileName(from json: [String: Any]) -> String? {
        if let data = json["data"] as? [String: Any] { return data["file_name"] as? String }
        return nil
    }
}
