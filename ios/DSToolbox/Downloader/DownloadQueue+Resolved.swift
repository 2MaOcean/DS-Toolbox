import Foundation

extension DownloadQueue {
    @discardableResult
    func enqueue(link: ResolvedLink, kind: DriveKind, options: DownloadOptions? = nil) throws -> UUID {
        let cookie = link.headers["Cookie"] ?? ""
        let ua = link.headers["User-Agent"] ?? ""
        let cred = DriveCredential(kind: kind.rawValue, cookieHeader: cookie, userAgent: ua, savedAt: Date())
        return try enqueue(url: link.url, fileName: link.fileName, credential: cred, kind: kind, options: options)
    }
}
