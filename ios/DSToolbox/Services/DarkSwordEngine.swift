import Foundation
import Combine

@MainActor
final class DarkSwordEngine: ObservableObject {
    static let shared = DarkSwordEngine()
    @Published private(set) var running = false
    @Published private(set) var stage = "待启动"
    @Published private(set) var logs: [String] = []
    @Published private(set) var lastReport: EnvironmentReport?
    private init() {}

    func run(force: Bool = false) async {
        guard !running else { return }
        running = true
        logs.removeAll()

        stage = "1/5 环境检查"
        let report = EnvironmentGuard.shared.check()
        lastReport = report
        log("iOS \(report.iosVersion) · \(report.chip.rawValue) · \(report.sandboxLevel.rawValue)")
        log("越狱:\(report.isJailbroken) TS:\(report.isTrollStore) 偏移:\(report.hasOffset)")

        try? await Task.sleep(nanoseconds: 400_000_000)
        if report.blockedReason != nil && !force {
            log("限制: \(report.blockedReason!)")
            stage = "终止"
            running = false
            return
        }
        stage = "2/5 初始化 KRW"
        let krw = DarkSwordKRW.shared
        if krw.initialize() {
            log("KRW 就绪, 内核基址 0x\(String(krw.kernelBase, radix: 16))")
        } else {
            log("KRW 初始化失败（需越狱/TrollStore 或偏移不匹配）")
            stage = "失败"
            running = false
            return
        }

        stage = "3/5 验证内核读写"
        if let header = krw.read(address: krw.kernelBase, size: 4) {
            let magic = header.withUnsafeBytes { $0.load(as: UInt32.self) }
            log("内核魔数: 0x\(String(format: "%08x", magic))")
            log(magic == 0xFEEDFACF ? "✅ 内核读写验证成功" : "⚠️ 魔数异常，偏移可能不匹配")
        } else {
            log("❌ 内核读取失败")
        }

        stage = "4/5 提权后能力"
        log(report.isJailbroken ? "已越狱，可写系统文件" : "仅 KRW 可读，写系统需越狱")

        stage = "5/5 完成"
        log("流程结束")
        running = false
    }

    func shutdown() {
        DarkSwordKRW.shared.deinitialize()
        stage = "已关闭"
    }

    private func log(_ s: String) {
        logs.append("[\(Date().formatted(date: .omitted, time: .standard))] \(s)")
    }
}
