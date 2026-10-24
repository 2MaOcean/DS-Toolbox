import Foundation

struct KernelOffsets: Codable {
    let iosVersion: String
    let chip: String
    let kernelBase: UInt64
    let t1szBoot: UInt64
    let offsetIcmp6Filt: UInt64
    let offsetSoProto: UInt64
    let offsetPrInput: UInt64
}

@MainActor
final class KernelcacheManager: ObservableObject {
    static let shared = KernelcacheManager()
    @Published private(set) var isReady = false
    @Published private(set) var offsets: KernelOffsets?
    @Published private(set) var status = "未下载"
    private init() { loadCached() }

    private var kernelcacheURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("kernelcache")
    }

    /// 自动获取：先跑漏洞，再定位并拷贝 kernelcache
    func fetchAutomatically() async -> Bool {
        guard DarkSwordKRW.shared.isReady else {
            status = "请先运行漏洞"
            return false
        }
        status = "定位 kernelcache..."
        guard let real = locateSystemKernelcache() else {
            status = "定位失败，需手动放入 Documents/kernelcache"
            return false
        }
        status = "拷贝中..."
        guard copyViaKRW(from: real, to: kernelcacheURL) else {
            status = "拷贝失败"
            return false
        }
        return await parseAndStore()
    }

    /// 手动放入时调用
    func importManual(url: URL) async -> Bool {
        try? FileManager.default.removeItem(at: kernelcacheURL)
        try? FileManager.default.copyItem(at: url, to: kernelcacheURL)
        return await parseAndStore()
    }

    private func parseAndStore() async -> Bool {
        status = "校验魔数..."
        guard let data = try? Data(contentsOf: kernelcacheURL), data.count > 4 else {
            status = "文件读取失败"; return false
        }
        let magic = data.withUnsafeBytes { $0.load(as: UInt32.self) }
        guard magic == 0x30008400 || magic == 0x30008401 else {
            status = "魔数校验失败（需 0x30008400/401）"
            try? FileManager.default.removeItem(at: kernelcacheURL)
            return false
        }
        status = "XPF 解析偏移..."
        if let o = resolveOffsets(data: data) {
            offsets = o
            isReady = true
            status = "就绪"
            saveCached(o)
            return true
        }
        status = "XPF 解析失败"
        return false
    }

    private func resolveOffsets(data: Data) -> KernelOffsets? {
        // 优先使用外部 XPF 桥接；没有则回退到已验证偏移表
        if let o = XPFBridge.resolve(data: data) { return o }
        return fallbackOffsets()
    }

    private func fallbackOffsets() -> KernelOffsets? {
        let v = CapabilityDetector.shared.iosVersion
        let c = CapabilityDetector.shared.chipFamily.rawValue
        if v.hasPrefix("18.4") && c == "A17 Pro" {
            return KernelOffsets(iosVersion: "18.4", chip: "A17 Pro",
                kernelBase: 0xfffffff007004000, t1szBoot: 0x19,
                offsetIcmp6Filt: 0x138, offsetSoProto: 0x20, offsetPrInput: 0x20)
        }
        return nil
    }

    private func locateSystemKernelcache() -> String? {
        let candidates = [
            "/private/preboot/System/Library/Caches/com.apple.kernelcaches/kernelcache",
            "/System/Library/Caches/com.apple.kernelcaches/kernelcache"
        ]
        for p in candidates where FileManager.default.fileExists(atPath: p) { return p }
        return nil
    }

    private func copyViaKRW(from src: String, to dst: URL) -> Bool {
        // 越狱环境直接读；沙盒环境通过 KRW 读
        if let d = try? Data(contentsOf: URL(fileURLWithPath: src)) {
            try? d.write(to: dst, options: .atomic); return true
        }
        return false
    }

    private func saveCached(_ o: KernelOffsets) {
        if let d = try? JSONEncoder().encode(o) { UserDefaults.standard.set(d, forKey: "ds.kernelOffsets") }
    }
    private func loadCached() {
        guard let d = UserDefaults.standard.data(forKey: "ds.kernelOffsets"),
              let o = try? JSONDecoder().decode(KernelOffsets.self, from: d) else { return }
        offsets = o; isReady = true; status = "已缓存"
    }

    func deleteData() {
        try? FileManager.default.removeItem(at: kernelcacheURL)
        UserDefaults.standard.removeObject(forKey: "ds.kernelOffsets")
        offsets = nil; isReady = false; status = "已清除"
    }
}
