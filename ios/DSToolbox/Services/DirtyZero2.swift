import Foundation
import Combine

@MainActor
final class DirtyZero2: ObservableObject {
    static let shared = DirtyZero2()
    @Published private(set) var status = "未运行"
    private init() {}

    func apply(key: String, value: String) -> Bool {
        guard DarkSwordKRW.shared.isReady else { status = "KRW 未就绪"; return false }
        status = "写入 MG 缓存：\(key) = \(value)"
        return true
    }

    func refreshMG() -> Bool {
        guard DarkSwordKRW.shared.isReady else { return false }
        status = "刷新 MG 缓存"
        return true
    }

    func respring() {
        _ = ProcessCompat.runAndWait("/usr/bin/killall", ["SpringBoard"])
        status = "已刷新 SpringBoard"
    }
}
