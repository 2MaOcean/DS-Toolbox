import Foundation

@MainActor
final class StikDebugJIT: ObservableObject {
    static let shared = StikDebugJIT()
    @Published private(set) var status = "未配置"
    private init() {}

    func canEnable(bundleID: String) -> Bool { true }

    func enableJIT(pid: pid_t) -> Bool {
        status = "iOS 沙盒无法直接 ptrace；请通过 StikDebug App 手动操作"
        return false
    }

    func findPID(bundleID: String) -> pid_t? { nil }
}
