import Foundation

extension CommandEngine {
    func runPKG(_ args: [String]) -> CommandResult {
        guard let sub = args.first else {
            let h = "pkg install <n>\npkg list\npkg search <kw>\npkg update"
            return .ok(h)
        }
        let rest = Array(args.dropFirst())
        switch sub {
        case "install":
            if ShellBackend.which("apt") != nil {
                return runExternal("apt", ["install", "-y"] + rest)
            }
            if ShellBackend.which("apk") != nil {
                return runExternal("apk", ["add"] + rest)
            }
            return .err("没有可用的包管理器")
        case "remove":
            if ShellBackend.which("apt") != nil {
                return runExternal("apt", ["remove", "-y"] + rest)
            }
            if ShellBackend.which("apk") != nil {
                return runExternal("apk", ["del"] + rest)
            }
            return .err("没有可用的包管理器")
        case "list":
            if ShellBackend.which("dpkg") != nil {
                return runExternal("dpkg", ["-l"])
            }
            if ShellBackend.which("apk") != nil {
                return runExternal("apk", ["info"])
            }
            return .err("没有 dpkg/apk")
        case "search":
            if ShellBackend.which("apt") != nil {
                return runExternal("apt", ["search"] + rest)
            }
            if ShellBackend.which("apk") != nil {
                return runExternal("apk", ["search"] + rest)
            }
            return .err("没有包管理器")
        case "update":
            if ShellBackend.which("apt") != nil {
                return runExternal("apt", ["update"])
            }
            return .err("没有 apt")
        default:
            return .err("pkg: 未知子命令 \(sub)")
        }
    }
}
