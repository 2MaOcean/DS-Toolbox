import Foundation

struct KernelCacheFetcher {
    static let shared = KernelCacheFetcher()

    private var docKCPath: URL {
        let d = FileManager.default
        let u = d.urls(for: .documentDirectory,
                       in: .userDomainMask)[0]
        return u.appendingPathComponent("kernelcache")
    }

    func fetch(allowNetwork: Bool = true) async throws -> URL {
        if FileManager.default.fileExists(
            atPath: docKCPath.path) {
            return docKCPath
        }
        if let local = try? copyFromSystemPath() {
            return local
        }
        if allowNetwork {
            return try await downloadForCurrentBuild()
        }
        throw FetchError.kcacheUnavailable
    }

extension KernelCacheFetcher {
    enum FetchError: LocalizedError {
        case localPathNotFound
        case kcacheUnavailable
        case networkDownloadNotConfigured

        var errorDescription: String? {
            switch self {
            case .localPathNotFound:
                return "未能从 /private/preboot 定位 kernelcache"
            case .kcacheUnavailable:
                return "kernelcache 不可用"
            case .networkDownloadNotConfigured:
                return "联网下载尚未配置"
            }
        }
    }
}
