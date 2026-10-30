import Foundation
import Darwin

enum ShellSpawner {
    struct Result { let out: String; let err: String; let code: Int32 }

    static func spawn(path: String, args: [String], cwd: URL? = nil) -> Result {
        var stdinPipe: [Int32] = [0, 0]
        var stdoutPipe: [Int32] = [0, 0]
        var stderrPipe: [Int32] = [0, 0]
        guard pipe(&stdinPipe) == 0, pipe(&stdoutPipe) == 0, pipe(&stderrPipe) == 0 else {
            return Result(out: "", err: "pipe failed", code: -1)
        }
        var fileActions: posix_spawn_file_actions_t?
        posix_spawn_file_actions_init(&fileActions)
        posix_spawn_file_actions_adddup2(&fileActions, stdinPipe[0], 0)
        posix_spawn_file_actions_adddup2(&fileActions, stdoutPipe[1], 1)
        posix_spawn_file_actions_adddup2(&fileActions, stderrPipe[1], 2)
        if let c = cwd { posix_spawn_file_actions_addchdir_np(&fileActions, c.path) }
        posix_spawn_file_actions_addclose(&fileActions, stdinPipe[1])
        posix_spawn_file_actions_addclose(&fileActions, stdoutPipe[0])
        posix_spawn_file_actions_addclose(&fileActions, stderrPipe[0])

        var cArgs: [UnsafeMutablePointer<CChar>?] = args.map { strdup($0) }
        cArgs.append(nil)
        defer { cArgs.forEach { if let p = $0 { free(p) } } }

        var pid: pid_t = 0
        let rc = posix_spawn(&pid, path, &fileActions, nil, cArgs, environ)
        posix_spawn_file_actions_destroy(&fileActions)
        close(stdinPipe[0]); close(stdoutPipe[1]); close(stderrPipe[1])
        close(stdinPipe[1])
        guard rc == 0 else {
            close(stdoutPipe[0]); close(stderrPipe[0])
            return Result(out: "", err: "spawn failed: \(String(cString: strerror(rc)))", code: rc)
        }
        let outData = readAll(fd: stdoutPipe[0])
        let errData = readAll(fd: stderrPipe[0])
        close(stdoutPipe[0]); close(stderrPipe[0])
        var status: Int32 = 0
        waitpid(pid, &status, 0)
        let code = (status >> 8) & 0xFF
        return Result(out: String(decoding: outData, as: UTF8.self),
                      err: String(decoding: errData, as: UTF8.self),
                      code: code)
    }

    private static func readAll(fd: Int32) -> Data {
        var data = Data(); var buf = [UInt8](repeating: 0, count: 4096)
        while true {
            let n = read(fd, &buf, buf.count)
            if n <= 0 { break }
            data.append(buf, count: n)
        }
        return data
    }
}
