import Foundation
import UIKit

final class IPAInstallService {
    static let shared = IPAInstallService()
    private init() {}

    enum InstallError: LocalizedError {
        case trollStoreNotFound, otaFailed
        var errorDescription: String? {
            switch self {
            case .trollStoreNotFound: return "未安装 TrollStore"
            case .otaFailed: return "OTA 安装地址失败"
            }
        }
    }

    @MainActor
    func install(ipa: URL, using method: InstallMethod) async throws {
        switch method {
        case .trollStore:
            guard TrollStoreService.shared.isInstalled else { throw InstallError.trollStoreNotFound }
            let scheme = "apple-magnifier://install?url=\(ipa.path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            if let u = URL(string: scheme) { await UIApplication.shared.open(u) }
        case .itmsServices:
            guard let u = URL(string: "itms-services://?action=download-manifest&url=\(ipa.path)") else { throw InstallError.otaFailed }
            await UIApplication.shared.open(u)
        case .documentPicker:
            presentShare(ipa: ipa)
        }
    }

    @MainActor
    private func presentShare(ipa: URL) {
        let av = UIActivityViewController(activityItems: [ipa], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(av, animated: true)
        }
    }
}
