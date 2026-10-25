import Foundation
import Darwin
import Combine

@MainActor
final class StikDebugJIT: ObservableObject {
    static let shared = StikDebugJIT()
    @Published private(set) var status = "未配置"
    private init() {}

    private static let PT_ATTACHEXC: CInt = 14

    func canEnable(bundleID: String) -> Bool { true }

    func enableJIT(pid: pid_t) -> Bool {
        let r = ptrace(Self.PT_ATTACHEXC, pid, nil, nil)
        if r == 0 { status = "已附加 pid \(pid)"; return true }
        status = "ptrace 失败 errno=\(errno)"
        return false
    }

    func findPID(bundleID: String) -> pid_t? {
        JailbreakJITProvider.findPID(bundleID: bundleID)
    }
}
