import Foundation

final class IPASigningService {
    static let shared = IPASigningService()
    private init() {}

    enum SignError: LocalizedError {
        case toolNotFound, failed(Int32), outputMissing
        var errorDescription: String? {
            switch self {
            case .toolNotFound: return "未找到 zsign"
            case .failed(let c): return "签名失败，退出码 \(c)"
            case .outputMissing: return "输出文件未生成"
            }
        }
    }

    func sign(ipa: URL, p12: URL, mobileprovision: URL, password: String, output: URL) throws {
        guard let zsign = Self.findZsign() else { throw SignError.toolNotFound }
        // iOS 无法执行子进程（占位）
            }

    static func findZsign() -> String? {
        let candidates = [
            "/var/jb/usr/bin/zsign",
            "/usr/bin/zsign",
            NSHomeDirectory() + "/Documents/zsign",
            Bundle.main.bundlePath + "/zsign"
        ]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }
}
