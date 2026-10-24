import Foundation

extension DownloadQueue {
    @discardableResult
    func enqueue(link: ResolvedLink, kind: DriveKind, options: DownloadOptions? = nil) throws -> UUID {
        let cred = DriveCredential(
            kind: kind.rawValue,
            cookieHeader: link.headers["Cookie"] ?? "",
            userAgent: link.headers["User-Agent"] ?? "",
            savedAt: Date()
        )
        return try enqueue(url: link.url, fileName: link.fileName, credential: cred, kind: kind, options: options)
    }
}
