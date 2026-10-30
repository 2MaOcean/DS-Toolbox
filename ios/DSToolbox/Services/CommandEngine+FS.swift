import Foundation

extension CommandEngine {
    func runLS(_ args: [String]) -> CommandResult {
        var path = "."; var long = false; var all = false
        for a in args {
            if a.hasPrefix("-") { if a.contains("l") { long = true }; if a.contains("a") { all = true } }
            else { path = a }
        }
        let url = resolve(path)
        guard let entries = try? fm.contentsOfDirectory(at: url,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey]) else {
            return .err("ls: \(path): No such file or directory")
        }
        let sorted = entries.filter { all || !$0.lastPathComponent.hasPrefix(".") }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
        if sorted.isEmpty { return .ok("") }
        if long {
            let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd HH:mm"
            return .ok(sorted.map { e -> String in
                let v = try? e.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey])
                let d = v?.isDirectory ?? false
                let p = d ? "drwxr-xr-x" : "-rw-r--r--"
                return String(format: "%@ %8d %@ %@", p, v?.fileSize ?? 0, fmt.string(from: v?.contentModificationDate ?? Date()), e.lastPathComponent + (d ? "/" : ""))
            }.joined(separator: "\n"))
        }
        return .ok(sorted.map { $0.lastPathComponent + (FileSorter.isDirectory($0) ? "/" : "") }.joined(separator: "  "))
    }

    func runCD(_ args: [String]) -> CommandResult {
        let url = resolve(args.first ?? "~")
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue else {
            return .err("cd: \(args.first ?? "~"): No such directory")
        }
        updateCwd(url)
        return .cd(url)
    }

    func runCAT(_ args: [String]) -> CommandResult {
        guard !args.isEmpty else { return .err("cat: missing file") }
        var out = ""
        for p in args {
            guard let data = try? Data(contentsOf: resolve(p)) else { out += "cat: \(p): No such file\n"; continue }
            out += String(data: data, encoding: .utf8) ?? "(二进制 \(data.count) 字节)\n"
        }
        return .ok(out)
    }

    func runMKDIR(_ args: [String]) -> CommandResult {
        guard !args.isEmpty else { return .err("mkdir: missing argument") }
        do { for p in args { try fm.createDirectory(at: resolve(p), withIntermediateDirectories: true) }; return .ok("") }
        catch { return .err("mkdir: \(error.localizedDescription)") }
    }

    func runTOUCH(_ args: [String]) -> CommandResult {
        guard !args.isEmpty else { return .err("touch: missing argument") }
        for p in args { let u = resolve(p); if !fm.fileExists(atPath: u.path) { fm.createFile(atPath: u.path, contents: nil) } }
        return .ok("")
    }

    func runRM(_ args: [String]) -> CommandResult {
        var rec = false; var targets: [String] = []
        for a in args { if a.hasPrefix("-") { if a.contains("r") || a.contains("R") { rec = true } } else { targets.append(a) } }
        guard !targets.isEmpty else { return .err("rm: missing argument") }
        do {
            for p in targets {
                let url = resolve(p); var isDir: ObjCBool = false
                if fm.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue, !rec {
                    return .err("rm: \(p): is a directory (use -r)")
                }
                try fm.removeItem(at: url)
            }
            return .ok("")
        } catch { return .err("rm: \(error.localizedDescription)") }
    }

    func runCP(_ args: [String]) -> CommandResult {
        guard args.count == 2 else { return .err("cp: usage: cp <src> <dst>") }
        let src = resolve(args[0]); var dst = resolve(args[1])
        do {
            if FileSorter.isDirectory(dst) { dst = dst.appendingPathComponent(src.lastPathComponent) }
            try fm.copyItem(at: src, to: dst); return .ok("")
        } catch { return .err("cp: \(error.localizedDescription)") }
    }

    func runMV(_ args: [String]) -> CommandResult {
        guard args.count == 2 else { return .err("mv: usage: mv <src> <dst>") }
        let src = resolve(args[0]); var dst = resolve(args[1])
        do {
            if FileSorter.isDirectory(dst) { dst = dst.appendingPathComponent(src.lastPathComponent) }
            try fm.moveItem(at: src, to: dst); return .ok("")
        } catch { return .err("mv: \(error.localizedDescription)") }
    }
}
