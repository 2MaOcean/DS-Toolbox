import Foundation

/// iOS 沙盒无法用 Foundation.Process（macOS 独占）。
/// 用 POSIX posix_spawn 实现，越狱/TrollStore 下真实执行，沙盒下返回 EPERM。
enum ProcessCompat {
    @discardableResult
    static func run(_ path: String, args: [String]) -> Int32 {
        var argv: [UnsafeMutablePointer<CChar>?] = args.map { strdup($0) }
        argv.append(nil)
        defer { for a in argv { if let a { free(a) } } }

        var pid: pid_t = 0
        let status = posix_spawn(&pid, path, nil, nil, argv, environ)
        if status == 0 { waitpid(pid, nil, 0) }
        return status
    }

    /// 执行并等待；返回 0 表示成功
    static func runAndWait(_ path: String, _ args: [String]) -> Bool {
        run(path, args: args) == 0
    }
}
