import Foundation
struct ImportedIPA: Identifiable { let id = UUID(); let fileURL: URL; let fileName: String; let fileSize: Int64; var bundleID: String?; var appName: String?; var version: String?; var isEncrypted: Bool = false }
struct SigningCertificate: Codable, Identifiable { var id: String { uuid }; let uuid: String; let displayName: String; let p12Path: String; let provisionPath: String; let p12Password: String; let expiresAt: Date?; let teamID: String?; let isFreeAccount: Bool }
