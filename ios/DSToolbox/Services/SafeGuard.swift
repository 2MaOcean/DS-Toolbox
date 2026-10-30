import Foundation

enum SafeGuard {
    struct Verdict {
        let block: Bool
        let reason: String
    }

    static let hardBlocks: [String] = [
        "rm -rf /", "rm -rf /var", "rm -rf /System", "rm -rf /private",
        "mkfs", "dd if=", ":(){:|:&};:", "shutdown", "reboot", "halt",
        "launchctl unload /System", "nvram -c"
    ]

    static let warnPatterns: [String] = [
        "rm -rf", "apt remove", "apt purge", "dpkg -r", "dpkg --purge",
        "dpkg -i", "killall", "kill -9", "chmod -R 777"
    ]

    static func check(_ cmd: String) -> Verdict {
        let lower = cmd.lowercased()
        for h in hardBlocks where lower.contains(h) {
            return Verdict(block: true, reason: "命令被拦截：\(h) 会破坏系统")
        }
        if lower.contains("apt remove") && (lower.contains("bash") || lower.contains("dpkg") || lower.contains("apt")) {
            return Verdict(block: true, reason: "禁止卸载包管理器自身")
        }
        for w in warnPatterns where lower.contains(w) {
            return Verdict(block: false, reason: "危险命令：\(w)，请确认")
        }
        return Verdict(block: false, reason: "")
    }
}
