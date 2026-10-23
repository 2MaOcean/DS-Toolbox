import Foundation
import UIKit
enum InstallMethod: String { case trollStore, itmsServices; var label: String { self == .trollStore ? "TrollStore" : "OTA 安装" } }
final class IPAInstallService {
    static let shared = IPAInstallService(); private init() {}
    func install(ipa: URL, using method: InstallMethod) async throws {
        if method == .trollStore {
            let url = URL(string: "apple-magnifier://install?path=\(ipa.path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")")!
            await MainActor.run { UIApplication.shared.open(url) }
        } else { throw NSError(domain: "Install", code: 1, userInfo: [NSLocalizedDescriptionKey: "OTA 安装需要本地服务器支持，暂未接入"]) }
    }
}
