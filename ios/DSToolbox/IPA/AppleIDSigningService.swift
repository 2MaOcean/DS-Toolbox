import Foundation

final class AppleIDSigningService {
    static let shared = AppleIDSigningService()
    private init() {}

    enum SignError: LocalizedError {
        case notImplemented, invalidCredentials
        var errorDescription: String? {
            switch self {
            case .notImplemented: return "Anisette 框架未集成"
            case .invalidCredentials: return "Apple ID 或密码错误"
            }
        }
    }

    func sign(appleID: String, password: String, ipa: URL, output: URL) async throws {
        // Anisette 数据获取 → GS 认证 → 生成证书 → 复用 IPASigningService
        throw SignError.notImplemented
    }
}
