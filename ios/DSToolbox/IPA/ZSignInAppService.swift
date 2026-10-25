import Foundation
import ZIPFoundation
import ZSign

final class ZSignInAppService {
    static let shared = ZSignInAppService()
    private init() {}

    enum SignError: LocalizedError {
        case unzipFailed, appNotFound, signFailed(Int32), repackFailed, outputMissing
        var errorDescription: String? {
            switch self {
            case .unzipFailed: return "IPA 解压失败"
            case .appNotFound: return "未找到 Payload/*.app"
            case .signFailed(let c): return "zsign 签名失败，代码 \(c)"
            case .repackFailed: return "重新打包失败"
            case .outputMissing: return "签名输出未生成"
            }
        }
    }

    func sign(ipa: URL, p12: URL, mobileprovision: URL, password: String, outputDirectory: URL) throws -> URL {
        let fm = FileManager.default
        let work = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let extract = work.appendingPathComponent("Extracted", isDirectory: true)
        try fm.createDirectory(at: extract, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: work) }

        guard let archive = try? Archive(url: ipa, accessMode: .read) else { throw SignError.unzipFailed }
        for entry in archive {
            _ = try? archive.extract(entry, to: extract)
        }

        let payload = extract.appendingPathComponent("Payload", isDirectory: true)
        guard let apps = try? fm.contentsOfDirectory(at: payload, includingPropertiesForKeys: nil),
              let appDir = apps.first(where: { $0.pathExtension == "app" }) else {
            throw SignError.appNotFound
        }

        let code = zsign(
            appDir.path,
            p12.path,
            password,
            mobileprovision.path,
            nil,
            nil,
            nil
        )
        guard code == 0 else { throw SignError.signFailed(code) }

        let outputIPA = outputDirectory.appendingPathComponent("signed_\(ipa.lastPathComponent)")
        try? fm.removeItem(at: outputIPA)
        guard let out = try? Archive(url: outputIPA, accessMode: .create) else { throw SignError.repackFailed }

        let enumerator = fm.enumerator(at: extract, includingPropertiesForKeys: [.isDirectoryKey], options: [])!
        for case let fileURL as URL in enumerator {
            let rel = fileURL.path.replacingOccurrences(of: extract.path + "/", with: "")
            if rel.isEmpty { continue }
            let isDir = (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            if isDir {
                try? out.addEntry(with: rel + "/", type: .directory, uncompressedSize: Int64(0), provider: { _, _ in Data() })
            } else {
                try? out.addEntry(with: rel, fileURL: fileURL)
            }
        }
        guard fm.fileExists(atPath: outputIPA.path) else { throw SignError.outputMissing }
        return outputIPA
    }
}
