import Foundation

struct ResolvedLink {
    let url: URL
    let headers: [String: String]
    let fileName: String
    let expectedSize: Int64?
    let resolvedAt: Date
}

enum DriveKind: String, CaseIterable, Codable, Identifiable {
    case baidu, quark, guangya, cmcc, telecom
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .baidu: return "百度网盘"
        case .quark: return "夸克网盘"
        case .guangya: return "光亚网盘"
        case .cmcc: return "移动云盘"
        case .telecom: return "天翼云盘"
        }
    }
    var tier: String {
        switch self {
        case .baidu, .telecom: return "官方 API"
        case .guangya: return "客户端 API"
        case .quark, .cmcc: return "Cookie / 网页拦截"
        }
    }
}

enum ResolveError: LocalizedError {
    case unsupported, requiresOfficialClient, credentialExpired, notImplemented, riskControl
    var errorDescription: String? {
        switch self {
        case .unsupported: return "不支持的链接"
        case .requiresOfficialClient: return "该链接需官方客户端签名，请改用网页内下载"
        case .credentialExpired: return "凭证已过期，请重新登录"
        case .notImplemented: return "自动解析尚未实现，请使用网页内下载"
        case .riskControl: return "触发风控，请稍后重试"
        }
    }
}

protocol CloudDriveAdapter {
    var kind: DriveKind { get }
    var loginURL: URL { get }
    var requiredCookieNames: [String] { get }
    var userAgent: String { get }
    func canHandle(_ url: URL) -> Bool
    func resolve(_ url: URL, credential: DriveCredential) async throws -> ResolvedLink
}

extension CloudDriveAdapter {
    var userAgent: String {
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1"
    }
}
