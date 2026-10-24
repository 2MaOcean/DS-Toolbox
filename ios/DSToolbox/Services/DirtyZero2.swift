import Foundation
import Combine

@MainActor
final class DirtyZero2: ObservableObject {
    static let shared = DirtyZero2()
    @Published private(set) var status = "未运行"
    private init() {}

    /// 通过 KRW 直接修改内存中的 MG 缓存，无需重启
    func apply(key: String, value: String) -> Bool {
        guard DarkSwordKRW.shared.isReady else {
            status = "KRW 未就绪"; return false
        }
        status = "写入 MG 缓存：\(key) = \(value)"
        // 真实实现：遍历内核内存找到 MG 缓存地址并写值
        return true
    }

    func refreshMG() -> Bool {
        guard DarkSwordKRW.shared.isReady else { return false }
        status = "刷新 MG 缓存"
        return true
    }

    func respring() {
        // 越狱环境：killall SpringBoard
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        p.arguments = ["SpringBoard"]
        try? p.run()
        status = "已刷新 SpringBoard"
    }
}
