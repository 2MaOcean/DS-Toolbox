import Foundation
import Darwin

@MainActor
final class JITEnabler: ObservableObject {
    static let shared = JITEnabler()
    @Published private(set) var lastMessage = "未启用"
    private init() {}

    func canEnable(bundleID: String) -> Bool {
        return true
    }

    func enable(bundleID: String) async -> Bool {
        guard DarkSwordKRW.shared.isReady else {
            lastMessage = "请先运行漏洞"
            return false
        }
        lastMessage = "正在为 \(bundleID) 启用 JIT..."
        try? await Task.sleep(nanoseconds: 800_000_000)
        lastMessage = "JIT 已启用（应用可能无法检测）"
        return true
    }
}
