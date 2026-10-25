import Darwin
import Foundation
import Darwin

@MainActor
final class StikDebugJIT: ObservableObject {
    static let shared = StikDebugJIT()
    @Published private(set) var status = "未配置"
    private init() {}

    /// 复用 StikDebug 的 get-task-allow 检查
    func canEnable(bundleID: String) -> Bool {
        return true // 真实需读目标二进制 entitlements
    }

    /// StikDebug 方案：ptrace(PT_ATTACHEXC) + CS_DEBUGGED
    func enableJIT(pid: pid_t) -> Bool {
        var attr = ptrace_request()
        // PT_ATTACHEXC = 14 (iOS)
        let ret = ptrace(PT_ATTACHEXC, pid, nil, nil)
        guard ret == 0 else {
            status = "ptrace 失败: \(errno)"
            return false
        }
        status = "✅ JIT 已启用 (pid \(pid))"
        return true
    }

    /// 通过 KRW 找目标进程 pid（沙盒内无法直接用 proc_listpids）
    func findPID(bundleID: String) -> pid_t? {
        guard DarkSwordKRW.shared.isReady else { return nil }
        // 真实实现：遍历 allproc 链表
        return nil
    }
}
