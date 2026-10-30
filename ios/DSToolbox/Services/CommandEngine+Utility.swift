import Foundation

extension CommandEngine {
    func runDF() -> CommandResult {
        let home = NSHomeDirectory()
        guard let a = try? fm.attributesOfFileSystem(forPath: home) else {
            return .err("df: failed")
        }
        let total = (a[.systemSize] as? NSNumber)?.int64Value ?? 0
        let free  = (a[.systemFreeSize] as? NSNumber)?.int64Value ?? 0
        let used  = total - free
        let line1 = "Filesystem      Size      Used     Avail"
        let line2 = "sandbox   \(formatBytes(total)) \(formatBytes(used)) \(formatBytes(free))"
        return .ok(line1 + "\n" + line2)
    }

    func runDU(_ args: [String]) -> CommandResult {
        let path = args.first ?? "."
        let url = resolve(path)
        guard fm.fileExists(atPath: url.path) else {
            return .err("du: \(path): No such file")
        }
        var total: Int64 = 0
        let keys: [URLResourceKey] = [.fileSizeKey]
        if let e = fm.enumerator(at: url, includingPropertiesForKeys: keys) {
            for case let f as URL in e {
                if let s = (try? f.resourceValues(forKeys: keys))?.fileSize {
                    total += Int64(s)
                }
            }
        }
        return .ok("\(formatBytes(total))\t\(path)")
    }

    func runFIND(_ args: [String]) -> CommandResult {
        let path = args.first ?? "."
        let url = resolve(path)
        var lines: [String] = []
        if let e = fm.enumerator(at: url, includingPropertiesForKeys: nil) {
            for case let f as URL in e {
                let p = f.path.replacingOccurrences(of: url.path, with: path)
                lines.append(p)
            }
        }
        return .ok(lines.isEmpty ? "(无匹配)" : lines.joined(separator: "\n"))
    }

    func runHEAD(_ args: [String]) -> CommandResult {
        return runHeadTail(args, tail: false)
    }

    func runTAIL(_ args: [String]) -> CommandResult {
        return runHeadTail(args, tail: true)
    }

    func runHeadTail(_ args: [String], tail: Bool) -> CommandResult {
        var count = 10
        var path: String?
        var i = 0
        while i < args.count {
            if args[i] == "-n", i + 1 < args.count {
                if let n = Int(args[i + 1]) {
                    count = n
                    i += 2
                    continue
                }
            }
            path = args[i]
            i += 1
        }
        guard let p = path else {
            return .err("usage: head/tail [-n N] <file>")
        }
        let data = try? Data(contentsOf: resolve(p))
        guard let d = data else {
            return .err("read failed: \(p)")
        }
        guard let s = String(data: d, encoding: .utf8) else {
            return .err("not utf8: \(p)")
        }
        let lines = s.components(separatedBy: "\n")
        let sel = tail ? Array(lines.suffix(count)) : Array(lines.prefix(count))
        return .ok(sel.joined(separator: "\n"))
    }

    func formatBytes(_ b: Int64) -> String {
        let u = ["B", "K", "M", "G", "T"]
        var v = Double(b)
        var i = 0
        while v >= 1024, i < u.count - 1 {
            v /= 1024
            i += 1
        }
        return String(format: "%.1f%@", v, u[i])
    }
}
