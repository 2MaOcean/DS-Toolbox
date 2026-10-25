import Foundation
import Darwin

struct JailbreakJITProvider {
    private static let PT_ATTACHEXC: CInt = 14

    static func enable(pid: pid_t) -> JITResult {
        let r = ptrace(Self.PT_ATTACHEXC, pid, nil, 0)
        if r == 0 { return JITResult(success: true, message: "已附加 pid \(pid)") }
        let e = errno
        if e == EPERM { return JITResult(success: false, message: "ptrace 权限不足（需越狱/TrollStore）") }
        return JITResult(success: false, message: "ptrace 失败 errno=\(e)")
    }

    static func findPID(bundleID: String) -> pid_t? {
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
        var size = 0
        guard sysctl(&mib, 4, nil, &size, nil, 0) == 0 else { return nil }
        let count = size / MemoryLayout<kinfo_proc>.stride
        var procs = [kinfo_proc](repeating: kinfo_proc(), count: count)
        guard sysctl(&mib, 4, &procs, &size, nil, 0) == 0 else { return nil }
        let target = bundleID.split(separator: ".").last.map(String.init) ?? bundleID
        for p in procs {
            let name = withUnsafeBytes(of: p.kp_proc.p_comm) {
                String(cString: $0.bindMemory(to: CChar.self).baseAddress!)
            }
            if name.contains(target) { return p.kp_proc.p_pid }
        }
        return nil
    }
}
