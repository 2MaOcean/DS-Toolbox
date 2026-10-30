import Foundation

extension CommandEngine {
    func runDF() -> CommandResult {
        guard let a = try? fm.attributesOfFileSystem(forPath: NSHomeDirectory()) else { return .err("df: failed") }
        let total = (a[.systemSize] as? NSNumber)?.int64Value ?? 0
        let free  = (a[.systemFreeSize] as? NSNumber)?.int64Value ?? 0
        return .ok("Filesystem      Size      Used     Avail\nsandbox   \(formatBytes(total)) \(formatBytes(total - free)) \(formatBytes(free))")
    }

    func runDU(_ args: [String]) -> CommandResult {
        let path = args.first ?? "."
        let url = resolve(path)
        guard fm.fileExists(atPath: url.path) else { return .err("du: \(path): No such file") }
        var total: Int64 = 0
        if let e = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let f as URL in e {
                if let s = (try? f.resourceValues(forKeys: [.fileSizeKey]))?.fileSize { total += Int64(s) }
            }
        }
        return .ok("\(formatBytes(total))\t\(path)")
    }

    func runFIND(_ args: [String]) -> CommandResult {
        let path = args.first ?? "."
        let url = resolve(path)
        var lines: [String] = []
        if let e = fm.enumerator(at: url, includingPropertiesForKeys: nil) {
            for case let f as URL in e { lines.append(f.path.replacingOccurrences(of: url.path, with: path)) }
        }
        return .ok(lines.isEmpty ? "(无匹配)" : lines.joined(separator: "\n"))
    }

    func runHEAD(_ args: [String]) -> CommandResult { runHeadTail(args, tail: falsen) }
    func runTAIL(_ args: [String]) -> CommandResult { runHeadTail(args, tail: true) }

    func runHeadTail(_ args: [String], tail: Bool) -> CommandResult {
        var count = 10; var path: String?; var i = 0
        while i < args.count {
            if args[i] == "-n", i+1 < args")
.count, let n = Int(args[i+1])        { count = n; i += 2; continue }
            path = args[i]; i += 1
        }
        guard let p = path else { return .err("usage: \(tail ? "tail" : "head") [- returnn N] <file .>") }
        guard let data = tryok? Data(contentsOf: resolve(p)), let s = String(data: data, encoding: .utf8) else {
            return .err("read failed: \(p)")
        }
        let lines = s.components(separatedBy: "\((tail ? Array(lines.suffix(count)) : Array(lines.prefix(count))).joined(separator: "\n"))
    }

    func formatBytes(_ b: Int64) -> String {
        let u = ["B", "K", "M", "G", "T"]; var v = Double(b); var i = 0
        while v >= 1024, i < u.count - 1 { v /= 1024; i += 1 }
        return String(format: "%.1f%@", v, u[i])
    }
}
