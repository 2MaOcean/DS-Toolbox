import Foundation

enum KernelCacheBootstrap {
    static func ensureReady() async throws -> URL {
        let kc = try await KernelCacheFetcher.shared.fetch()
        let off = try OffsetResolver.shared.resolve(kcache: kc)
        if let base = off["kernelBase"], base != 0 {
            UserDefaults.standard.set(base,
                forKey: "ds.kernelBase")
        }
        return kc
    }
}
