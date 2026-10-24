import Foundation
import Combine

@MainActor
final class KernelcacheAutoResolver: ObservableObject {
    static let shared = KernelcacheAutoResolver()
    @Published private(set) var status = "未开始"
    @Published private(set) var offsets: KernelOffsets?
    private init() { loadCached() }

    private var kcPath: String {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("kernelcache").path
    }

    func autoFetchAndResolve(ipswURL: String? = nil) async -> Bool {
        if let s = ipswURL, let url = URL(string: s) {
            status = "下载 IPSW..."
            if let tmp = try? await URLSession.shared.download(from: url).0 {
                try? FileManager.default.removeItem(atPath: kcPath)
                try? FileManager.default.moveItem(at: tmp, to: URL(fileURLWithPath: kcPath))
                return resolveOffsets()
            }
            status = "下载失败"
            return false
        }
        status = "请提供 IPSW 直链"
        return false
    }

    func importManual(url: URL) async -> Bool {
        try? FileManager.default.removeItem(atPath: kcPath)
        try? FileManager.default.copyItem(at: url, to: URL(fileURLWithPath: kcPath))
        return resolveOffsets()
    }

    private func resolveOffsets() -> Bool {
        status = "XPF 解析偏移..."
        var out = XPFOffsets()
        let ok = kcPath.withCString { xpf_resolve($0, &out) }
        guard ok else { status = "XPF 解析失败"; return false }
        let o = KernelOffsets(
            iosVersion: CapabilityDetector.shared.iosVersion,
            chip: CapabilityDetector.shared.chipFamily.rawValue,
            kernelBase: out.kernel_base, t1szBoot: out.t1sz_boot,
            offsetIcmp6Filt: out.offset_icmp6filt,
            offsetSoProto: out.offset_so_proto,
            offsetPrInput: out.offset_pr_input
        )
        offsets = o
        status = "✅ 偏移就绪"
        saveCached(o)
        return true
    }

    private func saveCached(_ o: KernelOffsets) {
        if let d = try? JSONEncoder().encode(o) {
            UserDefaults.standard.set(d, forKey: "ds.kernelOffsets")
        }
    }

    private func loadCached() {
        guard let d = UserDefaults.standard.data(forKey: "ds.kernelOffsets"),
              let o = try? JSONDecoder().decode(KernelOffsets.self, from: d) else { return }
        offsets = o; status = "已缓存"
    }

    func deleteData() {
        try? FileManager.default.removeItem(atPath: kcPath)
        UserDefaults.standard.removeObject(forKey: "ds.kernelOffsets")
        offsets = nil; status = "已清除"
    }
}
