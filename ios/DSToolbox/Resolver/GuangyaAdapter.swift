import Foundation

struct GuangyaAdapter: CloudDriveAdapter, CookieResolvableAdapter {
    let kind: DriveKind = .guangya
    var loginURL: URL { URL(string: "https://www.guangyapan.com/")! }
    var requiredCookieNames: [String] { ["token"] }
    var apiBase: String { "https://api.guangyapan.com" }

    func canHandle(_ url: URL) -> Bool {
        (url.host?.lowercased() ?? "").contains("guangya")
    }

    func resolve(_ url: URL, credential: DriveCredential) async throws -> ResolvedLink {
        try await resolveTemplate(url, cred: credential,
                                  path: "/file/download",
                                  params: ["url": url.absoluteString])
    }

    func extractDirectLink(from json: [String: Any]) -> String? { json["downloadUrl"] as? String }
    func extractFileName(from json: [String: Any]) -> String? { json["fileName"] as? String }
}
