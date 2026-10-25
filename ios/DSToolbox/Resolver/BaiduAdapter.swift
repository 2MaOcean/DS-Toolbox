import Foundation

struct BaiduAdapter: CloudDriveAdapter, CookieResolvableAdapter {
    let kind: DriveKind = .baidu
    var loginURL: URL { URL(string: "https://pan.baidu.com/")! }
    var requiredCookieNames: [String] { ["BDUSS"] }
    var apiBase: String { "https://pan.baidu.com" }

    func canHandle(_ url: URL) -> Bool {
        guard let h = url.host?.lowercased() else { return false }
        return h == "pan.baidu.com" || h.hasSuffix(".baidu.com")
    }

    func resolve(_ url: URL, credential: DriveCredential) async throws -> ResolvedLink {
        try await resolveTemplate(url, cred: credential,
                                  path: "/api/sharedownload",
                                  params: ["url": url.absoluteString])
    }

    func extractDirectLink(from json: [String: Any]) -> String? {
        if let list = json["list"] as? [[String: Any]], let first = list.first, let d = first["dlink"] as? String {
            return d
        }
        if let d = json["dlink"] as? String { return d }
        return nil
    }

    func extractFileName(from json: [String: Any]) -> String? {
        if let list = json["list"] as? [[String: Any]], let first = list.first {
            return first["server_filename"] as? String
        }
        return nil
    }
}
