import Foundation

@MainActor
final class KernelcacheAutoResolver: ObservableObject {
    static let shared = KernelcacheAutoResolver()
    @Published private(set) var status = "未开始"
    @Published private(set) var offsets: KernelOffsets?
    private init() {}

    private var kcURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("kernelcache")
    }

    /// 对应 Lara 的 getbmhash.swift + fetchkcache.swift 链路
    func autoFetchAndResolve() async -> Bool {
        guard DarkSwordKRW.shared.isReady else {
            status = "请先运行 DarkSword"
            return false
        }
        status = "定位 kernelcache..."
        guard let real = locateKernelcache() else {
            status = "未找到，需手动放入 Documents/kernelcache"
            return false
        }
        status = "拷贝中..."
        guard copyViaKRW(from: real) else {
            status = "拷贝失败"
            return false
        }
        return resolve()
    }

    func importManual(url: URL) async -> Bool {
        try? FileManager.default.removeItem(at: kcURL)
        try? FileManager.default.copyItem(at: url, to: kcURL)
        return resolve()
    }

    private func resolve() -> Bool {
        status = "XPF 解析偏移..."
        var out = DSOffsets()
        let ok = kcURL.path.withCString { ptr in
            xpf_resolve_offsets(ptr, &out)
        }
        guard ok else {
            status = "XPF 解析失败（需真实 XPF 库）"
            return false
        }
        let iosV = CapabilityDetector.shared.iosVersion
        let chip = CapabilityDetector.shared.chipFamily.rawValue
        let o = KernelOffsets(
            iosVersion: iosV, chip: chip,
            kernelBase: out.kernel_base, t1szBoot: out.t1sz_boot,
            offsetIcmp6Filt: out.offset_icmp6filt,
            offsetSoProto: out.offset_so_proto,
            offsetPrInput: out.offset_pr_input
        )
        offsets = o; status = "✅ 偏移就绪"
        if let d = try? JSONEncoder().encode(o) {
            UserDefaults.standard.set(d, forKey: "ds.kernelOffsets")
        }
        return true
    }

    private func locateKernelcache() -> String? {
        // getbmhash 逻辑：扫描 /private/preboot 下 UUID 目录
        let root = "/private/preboot"
        guard let dirs = try? FileManager.default.contentsOfDirectory(atPath: root) else { return nil }
        for d in dirs where d.contains("-") && !d.hasPrefix(".") {
            let p = "\(root)/\(d)/boot/System/Library/Caches/com.apple.kernelcaches/kernelcache"
            if FileManager.default.fileExists(atPath: p) { return p }
        }
        let fallback = "/System/Library/Caches/com.apple.kernelcaches/kernelcache"
        return FileManager.default.fileExists(atPath: fallback) ? fallback : nil
    }

    private func copyViaKRW(from path: String) -> Bool {
        if let d = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            try? d.write(to: kcURL, options: .atomic)
            return true
        }
        return false
    }

    func deleteData() {
        try? FileManager.default.removeItem(at: kcURL)
        UserDefaults.standard.removeObject(forKey: "ds.kernelOffsets")
        offsets = nil; status = "已清除"
    }
}
