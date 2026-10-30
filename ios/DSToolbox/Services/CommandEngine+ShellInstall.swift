import Foundation
import UIKit

extension CommandEngine {
    func runINSTALL(_ args: [String]) -> CommandResult {
        guard let p = args.first else {
            return .err("install: usage: install <file.ipa|file.deb>")
        }
        let url = resolve(p)
        guard fm.fileExists(atPath: url.path) else {
            return .err("install: \(p): 文件不存在")
        }
        let ext = url.pathExtension.lowercased()
        if ext == "deb" {
            if ShellBackend.current != .jailbreak {
                return .err("install deb: 需要越狱 + dpkg")
            }
            if ShellBackend.which("dpkg") == nil {
                return .err("install deb: 未找到 dpkg")
            }
            return runExternal("dpkg", ["-i", url.path])
        }
        if ext == "ipa" {
            if ShellBackend.current == .trollStore {
                let enc = url.path.addingPercentEncoding(
                    withAllowedCharacters: .urlQueryAllowed
                ) ?? url.path
                let s = "apple-magnifier://install?url=file://\(enc)"
                if let u = URL(string: s) {
                    DispatchQueue.main.async {
                        UIApplication.shared.open(u)
                    }
                    return .ok("已通过 TrollStore 打开安装")
                }
            }
            return .err("install ipa: 非 TrollStore 请去自签")
        }
        return .err("install: 不支持 .\(ext)")
    }
}
