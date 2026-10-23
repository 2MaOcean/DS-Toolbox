import Foundation
struct Aria2Task {
    var urls: [URL]; var out: String?; var dir: String?; var header: [String]
    var userAgent: String?; var referer: String?; var split: Int?; var maxConnectionPerServer: Int?
    var continueDownload: Bool; var checkIntegrity: Bool
}

enum Aria2Importer {
    static func parse(conf: String) -> [Aria2Task] {
        var tasks: [Aria2Task] = []; var current = empty()
        func flush() { if !current.urls.isEmpty { tasks.append(current) }; current = empty() }
        for line in conf.components(separatedBy: .newlines) {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.isEmpty || t.hasPrefix("#") { continue }
            if t.hasPrefix("http://") || t.hasPrefix("https://") || t.hasPrefix("magnet:") {
                if let u = URL(string: t) { current.urls.append(u) }; continue
            }
            let parts = t.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }
            let key = parts[0].trimmingCharacters(in: .whitespaces); let val = parts[1].trimmingCharacters(in: .whitespaces)
            if key == "out" && !current.urls.isEmpty { flush() }
            switch key {
            case "out": current.out = val; case "dir": current.dir = val; case "header": current.header.append(val)
            case "user-agent": current.userAgent = val; case "referer": current.referer = val; case "split": current.split = Int(val)
            case "max-connection-per-server": current.maxConnectionPerServer = Int(val)
            case "continue": current.continueDownload = (val.lowercased() == "true")
            case "check-integrity": current.checkIntegrity = (val.lowercased() == "true")
            default: break
            }
        }
        flush(); return tasks
    }
    private static func empty() -> Aria2Task {
        Aria2Task(urls: [], out: nil, dir: nil, header: [], userAgent: nil, referer: nil, split: nil, maxConnectionPerServer: nil, continueDownload: true, checkIntegrity: false)
    }
}
