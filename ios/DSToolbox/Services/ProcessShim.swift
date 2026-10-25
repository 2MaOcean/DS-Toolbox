import Foundation

/// iOS 沙盒环境无法使用 Foundation.Process 启动子进程。
/// 提供同名占位类型，避免各调用点编译报错；实际执行静默失败。
enum iOSProcess {
    static func run(_ path: String, _ args: [String]) -> Bool {
        print("[ProcessShim] iOS 无法执行 \(path) \(args.joined(separator: " "))")
        return false
    }
}
