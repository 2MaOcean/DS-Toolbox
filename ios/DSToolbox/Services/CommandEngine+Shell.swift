import Foundation
import UIKit

extension CommandEngine {
    func runExternal(_ cmd: String, _ args: [String]) -> CommandResult {
        let backend = ShellBackend.current
        guard backend.canSpawnBinaries else {
            return .err("\(cmd): 需要越狱或 TrollStore 环境。\n当前 \(backend.label)，仅支持内置命令（输入 help）")
        }
        guard let path = ShellBackend.which(cmd) else {
            return .err("\(cmd): not found。可尝试 pkg install \(cmd)")
        }
        let r = ShellSpawner.spawn(path: path, args: [cmd] + args, cwd: cwd)
        if r.code != 0 && !r.err.isEmpty {
            return .err(r.err.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return .ok(r.out)
    }

    func runPKG(_ args: [String]) -> CommandResult {
        guard let sub = args.first else {
            return .ok("pkg install <name>   安装包\npkg list             已安装\npkg search <kw>      搜索\npkg update           更新源")
        }
        let rest = Array(args.dropFirst())
        switch sub {
        case "install":
            if ShellBackend.which("apt") != nil { return runExternal("apt", ["install", "-y"] + rest) }
            if ShellBackend.which("apk") != nil { return runExternal("apk", ["add"] + rest) }
            return .err("没有可用的包管理器（apt/apk）。需要越狱或 TrollStore。")
        case "remove":
            if ShellBackend.which("apt") != nil { return runExternal("apt", ["remove", "-y"] + rest) }
            if ShellBackend.which("apk") != nil { return runExternal("apk", ["del"] + rest) }
            return .err("没有可用的包管理器")
        case "list":
            if ShellBackend.which("dpkg") != nil { return runExternal("dpkg", ["-l"]) }
            if ShellBackend.which("apk") != nil { return runExternal("apk", ["info"]) }
            return .err("没有 dpkg/apk")
        case "search":
            if ShellBackend.which("apt") != nil { return runExternal("apt", ["search"] + rest) }
            if ShellBackend.which("apk") != nil { return runExternal("apk", ["search"] + rest) }
            return .err("没有包管理器")
        case "update":
            if ShellBackend.which("apt") != nil { return runExternal("apt", ["update"]) }
            return .err("没有 apt")
        default:
            return .err("pkg: 未知子命令 \(sub)")
        }
    }

    func runINSTALL(_ args: [String]) -> CommandResult {
        guard let p = args.first else { return .err("install: usage: install <file.ipa|file.deb>") }
        let url = resolve(p)
        guard fm.fileExists(atPath: url.path) else { return .err("install: \(p): 文件不存在") }
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "deb":
            guard ShellBackend.current == .jailbreak, ShellBackend.which("dpkg") != nil else {
                return .err("install deb: 需要越狱 + dpkg")
            }
            return runExternal("dpkg", ["-i", url.path])
        case "ipa":
            if ShellBackend.current == .trollStore {
                let scheme = "apple-magnifier://install?url=file://\(url.path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? url.path)"
                if let u = URL(string: scheme) {
                    DispatchQueue.main.async { UIApplication.shared.open(u) }
                    return .ok("已通过 TrollStore 打开安装")
                }
            }
            return .err("install ipa: 非 TrollStore 环境需在 IPA 管理页手动自签")
        default:
            return .err("install: 不支持 .\(ext)，只支持 .ipa / .deb")
        }
    }
}
