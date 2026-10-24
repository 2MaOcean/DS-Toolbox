import Foundation
import Combine

@MainActor
final class ForceAttemptEngine: ObservableObject {
    static let shared = ForceAttemptEngine()
    @Published private(set) var method: AttemptMethod = .hybrid
    @Published private(set) var running = false
    @Published private(set) var logs: [String] = []
    private init() {}

    enum AttemptMethod: String, CaseIterable, Identifiable {
        case vfs = "VFS"
        case sbx = "SBX"
        case hybrid = "Hybrid"
        var id: String { rawValue }
    }

    func setMethod(_ m: AttemptMethod) { method = m }

    func run(force: Bool = true) async -> Bool {
        guard !running else { return false }
        running = true; logs.removeAll()

        log("尝试方式: \(method.rawValue), 强制: \(force)")
        if let r = EnvironmentManager.shared.info, r.isExcludedChip {
            log("M5/A19 硬件阻断，无法继续")
            running = false; return false
        }

        let krw = DarkSwordKRW.shared
        if !krw.isReady {
            log("初始化 KRW...")
            guard krw.initialize() else {
                log("KRW 初始化失败")
                running = false; return false
            }
            log("KRW 就绪, base=0x\(String(krw.kernelBase, radix: 16))")
        }

        try? await Task.sleep(nanoseconds: 500_000_000)
        switch method {
        case .vfs: log("VFS 路径：通过 kernelcache 文件系统挂载")
        case .sbx: log("SBX 路径：绕过沙盒扩展")
        case .hybrid: log("Hybrid：VFS + SBX 组合")
        }

        try? await Task.sleep(nanoseconds: 800_000_000)
        let verified = verifyKernelRead()
        log(verified ? "内核读写验证成功" : "内核读写验证失败，偏移可能不匹配")

        running = false
        return verified
    }

    private func verifyKernelRead() -> Bool {
        guard let header = DarkSwordKRW.shared.read(address: DarkSwordKRW.shared.kernelBase, size: 4) else { return false }
        let magic = header.withUnsafeBytes { $0.load(as: UInt32.self) }
        return magic == 0xFEEDFACF
    }

    private func log(_ s: String) {
        logs.append("[\(Date().formatted(date: .omitted, time: .standard))] \(s)")
    }
}
