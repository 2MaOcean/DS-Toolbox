import Foundation
import UIKit

extension CommandEngine {
    func runExternal(_ cmd: String, _ args: [String]) -> CommandResult {
        let backend = ShellBackend.current
        guard backend.canSpawnBinaries else {
            let m = "\(cmd): 需要越狱或 TrollStore 环境。"
            return .err(m + "\n当前 " + backend.label)
        }
        guard ShellBackend.which(cmd) != nil else {
            return .err("\(cmd): not found")
        }
        let shPath = ShellBackend.which("bash") ?? ShellBackend.which("sh")
        guard let sh = shPath else {
            return .err("no shell available")
        }
        let cwdQ = q(cwd.path)
        let cmdQ = ([cmd] + args).map { q($0) }.joined(separator: " ")
        let wrapper = "cd \(cwdQ) 2>/dev/null; \(cmdQ)"
        let r = ShellSpawner.spawn(path: sh, args: [sh, "-c", wrapper])
        if r.code != 0 && !r.err.isEmpty {
            return .err(r.err)
        }
        return .ok(r.out)
    }

    func q(_ s: String) -> String {
        let esc = s.replacingOccurrences(of: "'", with: "'\\''")
        return "'" + esc + "'"
    }
}
