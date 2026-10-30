import Foundation

final class CommandEngine: ObservableObject {
    static let shared = CommandEngine()
    @Published private(set) var cwd: URL
    let fm = FileManager.default

    private init() {
        cwd = URL(fileURLWithPath: NSHomeDirectory() + "/Documents", isDirectory: true)
    }

    func updateCwd(_ url: URL) { cwd = url }

    var cwdString: String {
        let home = NSHomeDirectory()
        if cwd.path == home { return "~" }
        if cwd.path.hasPrefix(home + "/") { return "~" + String(cwd.path.dropFirst(home.count)) }
        return cwd.path
    }

    func execute(_ raw: String) -> CommandResult {
        let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !line.isEmpty else { return .empty }
        let verdict = SafeGuard.check(line)
        if verdict.block { return .err(verdict.reason) }
        if let r = parseRedirect(line) { return runRedirect(r) }
        let tokens = tokenize(line)
        guard let cmd = tokens.first else { return .empty }
        let args = Array(tokens.dropFirst())
        switch cmd {
        case "pwd":    return .ok(cwd.path)
        case "whoami": return .ok(userName())
        case "help":   return .ok(helpText)
        case "clear":  return CommandResult(output: "", isError: false, newCwd: nil, shouldClear: true, shouldExit: false)
        case "exit":   return CommandResult(output: "", isError: false, newCwd: nil, shouldClear: false, shouldExit: true)
        case "ls":     return runLS(args)
        case "cd":     return runCD(args)
        case "cat":    return runCAT(args)
        case "mkdir":  return runMKDIR(args)
        case "touch":  return runTOUCH(args)
        case "rm":     return runRM(args)
        case "cp":     return runCP(args)
        case "mv":     return runMV(args)
        case "echo":   return .ok(args.joined(separator: " "))
        case "df":     return runDF()
        case "du":     return runDU(args)
        case "find":   return runFIND(args)
        case "head":   return runHEAD(args)
        case "tail":   return runTAIL(args)
        case "pkg":    return runPKG(args)
        case "install": return runINSTALL(args)
        case "apt", "dpkg", "apk", "bash", "sh", "ldid", "chmod", "chown", "ln", "which":
            return runExternal(cmd, args)
        default:       return .err("command not found: \(cmd)\n输入 help 查看支持的命令")
        }
    }

    func resolve(_ path: String) -> URL {
        if path == "~" { return URL(fileURLWithPath: NSHomeDirectory()) }
        if path.hasPrefix("~/") { return URL(fileURLWithPath: NSHomeDirectory() + String(path.dropFirst(1))) }
        if path.hasPrefix("/") { return URL(fileURLWithPath: path) }
        return cwd.appendingPathComponent(path).standardizedFileURL
    }

    func userName() -> String {
        switch ShellBackend.current {
        case .jailbreak:  return "root"
        case .trollStore: return "mobile"
        case .sandbox:    return "sandbox"
        }
    }

    func tokenize(_ s: String) -> [String] {
        var out: [String] = []; var cur = ""; var q: Character?
        for ch in s {
            if let quote = q {
                if ch == quote { q = nil } else { cur.append(ch) }
            } else if ch == "\"" || ch == "'" { q = ch }
            else if ch == " " || ch == "\t" { if !cur.isEmpty { out.append(cur); cur = "" } }
            else { cur.append(ch) }
        }
        if !cur.isEmpty { out.append(cur) }
        return out
    }

    struct Redirect { let text: String; let target: String; let append: Bool }

    func parseRedirect(_ line: String) -> Redirect? {
        guard let range = line.range(of: ">>") ?? line.range(of: ">") else { return nil }
        let append = line.contains(">>")
        let left = String(line[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
        let right = String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        guard left.hasPrefix("echo "), !right.isEmpty else { return nil }
        let text = String(left.dropFirst(5)).trimmingCharacters(in: .whitespaces)
        return Redirect(text: text, target: right, append: append)
    }

    func runRedirect(_ r: Redirect) -> CommandResult {
        let url = resolve(r.target)
        do {
            if r.append, fm.fileExists(atPath: url.path) {
                let h = try FileHandle(forWritingTo: url)
                h.seekToEndOfFile()
                try h.write(contentsOf: Data((r.text + "\n").utf8))
                try h.close()
            } else {
                try Data((r.text + "\n").utf8).write(to: url, options: .atomic)
            }
            return .ok("")
        } catch { return .err("写入失败: \(error.localizedDescription)") }
    }

    var helpText: String {
        """
        内置命令（沙盒可用）：
          pwd / whoami / ls / cd / cat / head / tail
          mkdir / touch / rm / cp / mv / echo / df / du / find
          echo <t> > <file>    写入
          echo <t> >> <file>   追加
          clear / exit / help
        真二进制（越狱或 TrollStore）：
          bash / sh / ldid / chmod / chown / ln / which
          apt / dpkg / apk
          pkg install <n> / pkg list / pkg update
          install <file.deb|file.ipa>
        """
    }
}
