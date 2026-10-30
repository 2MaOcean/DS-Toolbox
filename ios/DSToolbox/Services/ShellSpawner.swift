import Foundation
import Darwin

enum ShellSpawner {
    struct Result {
        let out: String
        let err: String
        let code: Int32
    }

    static func spawn(path: String, args: [String]) -> Result {
        var outP: [Int32] = [0, 0]
        var errP: [Int32] = [0, 0]
        guard pipe(&outP) == 0, pipe(&errP) == 0 else {
            return Result(out: "", err: "pipe failed", code: -1)
        }
        var fa: posix_spawn_file_actions_t?
        posix_spawn_file_actions_init(&fa)
        posix_spawn_file_actions_addopen(&fa, 0, "/dev/null", O_RDONLY, 0)
        posix_spawn_file_actions_adddup2(&fa, outP[1], 1)
        posix_spawn_file_actions_adddup2(&fa, errP[1], 2)
        posix_spawn_file_actions_addclose(&fa, outP[0])
        posix_spawn_file_actions_addclose(&fa, errP[0])
        posix_spawn_file_actions_addclose(&fa, outP[1])
        posix_spawn_file_actions_addclose(&fa, errP[1])
        var cArgs: [UnsafeMutablePointer<CChar>?] = args.map { strdup($0) }
        cArgs.append(nil)
        defer { cArgs.forEach { if let p = $0 { free(p) } } }
        var pid: pid_t = 0
        let rc = posix_spawn(&pid, path, &fa, nil, cArgs, environ)
        posix_spawn_file_actions_destroy(&fa)
        close(outP[1]); close(errP[1])
        guard rc == 0 else {
            close(outP[0]); close(errP[0])
            let m = String(cString: strerror(rc))
            return Result(out: "", err: "spawn failed: \(m)", code: rc)
        }
        let outD = readAll(fd: outP[0])
        let errD = readAll(fd: errP[0])
        close(outP[0]); close(errP[0])
        var status: Int32 = 0
        waitpid(pid, &status, 0)
        let code = (status >> 8) & 0xFF
        let o = String(decoding: outD, as: UTF8.self)
        let e = String(decoding: errD, as: UTF8.self)
        return Result(out: o, err: e, code: code)
    }

    private static func readAll(fd: Int32) -> Data {
        var data = Data()
        var buf = [UInt8](repeating: 0, count: 4096)
        while true {
            let n = read(fd, &buf, buf.count)
            if n <= 0 { break }
            data.append(buf, count: n)
        }
        return data
    }
}
