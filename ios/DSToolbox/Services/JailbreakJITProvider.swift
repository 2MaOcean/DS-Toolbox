import Foundation

struct JailbreakJITProvider {
    static func enable(pid: pid_t) -> JITResult {
        let available = FileManager.default.fileExists(atPath: "/var/jb")
            || TrollStoreService.shared.isInstalled
        guard available else {
            return JITResult(success: false, message: "需越狱或 TrollStore 环境")
        }
        return JITResult(success: false, message: "iOS 沙盒无法调用 ptrace；请在越狱环境用系统工具附加")
    }

    static func findPID(bundleID: String) -> pid_t? {
        return nil
    }
}
