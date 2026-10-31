import Foundation

struct KernelCacheFetcher {
    static let shared = KernelCacheFetcher()

    private var docKCPath: URL {
        let d = FileManager.default
        let u = d.urls(for: .documentDirectory,
                       in: .userDomainMask)[0]
        return u.appendingPathComponent("kernelcache")
    }

    func fetch(allowNetwork: Bool = true)
        async throws -> URL {
        let fm = FileManager.default
        if fm.fileExists(atPath: docKCPath.path) {
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

    private func copyFromSystemPath() throws -> URL {
        let preboot = URL(fileURLWithPath: "/private/preboot")
        let fm = FileManager.default
        let dirs = (try? fm.contentsOfDirectory(
            at: preboot,
            includingPropertiesForKeys: nil)) ?? []
        for dir in dirs {
            let c = dir.appendingPathComponent(
                "boot/kernelcache")
            if fm.fileExists(atPath: c.path) {
                try? fm.removeItem(at: docKCPath)
                try fm.copyItem(at: c, to: docKCPath)
                return docKCPath
            }
        }
        throw FetchError.localPathNotFound
    }

    private func downloadForCurrentBuild()
        async throws -> URL {
        throw FetchError.networkDownloadNotConfigured
    }
}

extension KernelCacheFetcher {
    enum FetchError: LocalizedError {
        case localPathNotFound
        case kcacheUnavailable
        case networkDownloadNotConfigured

        var errorDescription: String? {
            switch self {
            case .localPathNotFound:
                return "未能定位 kernelcache"
            case .kcacheUnavailable:
                return "kernelcache 不可用"
            case .networkDownloadNotConfigured:
                return "联网下载未配置"
            }
        }
    }
}
