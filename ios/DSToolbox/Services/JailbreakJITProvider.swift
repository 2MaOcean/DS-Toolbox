import Foundation
import Darwin

struct JailbreakJITProvider {
    static func enable(pid: pid_t) -> JITResult {
        guard ptrace(PT_ATTACHEXC, pid, nil, nil) == 0 else {
            return JITResult(success: false, message: "ptrace 失败：\(errno)")
        }
        return JITResult(success: true, message: "越狱 ptrace 已附加 (pid \(pid))")
    }

    static func findPID(bundleID: String) -> pid_t? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        task.arguments = ["-f", bundleID]
        let pipe = Pipe()
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()
        let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return pid_t(out.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
