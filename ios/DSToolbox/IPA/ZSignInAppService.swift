import Foundation
import ZIPFoundation

final class ZSignInAppService {
    static let shared = ZSignInAppService()
    private init() {}

    enum SignError: LocalizedError {
        case notImplemented
        var errorDescription: String? {
            "ZSign 内置签名暂不可用，请改用证书签名"
        }
    }

    func sign(ipa: URL, p12: URL, mobileprovision: URL, password: String, outputDirectory: URL) throws -> URL {
        throw SignError.notImplemented
    }
}
