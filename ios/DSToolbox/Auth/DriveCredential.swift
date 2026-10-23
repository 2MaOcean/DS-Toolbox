import Foundation
struct DriveCredential: Codable {
    let kind: String
    let cookieHeader: String
    let userAgent: String
    let savedAt: Date
    var isStale: Bool { Date().timeIntervalSince(savedAt) > 7 * 24 * 3600 }
}
