import Foundation
final class AppleIDSigningService {
    static let shared = AppleIDSigningService(); private init() {}
    func signIn(appleID: String, password: String, anisetteServer: URL, deviceUDID: String) async throws {
        throw NSError(domain: "AppleID", code: 1, userInfo: [NSLocalizedDescriptionKey: "Apple ID 自签需要完整的 Anisette 服务，本项目只提供调度框架"])
    }
}
