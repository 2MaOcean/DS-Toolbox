import Foundation
import ZIPFoundation

struct PluginInstaller {
    static let shared = PluginInstaller()

    var pluginsDir: URL {
        let d = FileManager.default
        let u = d.urls(for: .documentDirectory,
                       in: .userDomainMask)[0]
        return u.appendingPathComponent("Plugins")
    }

    func install(from zipURL: URL) throws -> PluginManifest {
        let fm = FileManager.default
        try fm.createDirectory(at: pluginsDir,
                               withIntermediateDirectories: true)
        let tmp = pluginsDir
            .appendingPathComponent("__tmp_\(UUID().uuidString)")
        try fm.createDirectory(at: tmp,
                               withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: tmp) }

        guard let archive = try? Archive(url: zipURL,
                                         accessMode: .read) else {
            throw InstallError.badArchive
        }
        for entry in archive {
            _ = try archive.extract(entry, to: tmp)
        }

        let mURL = tmp.appendingPathComponent("manifest.json")
        guard fm.fileExists(atPath: mURL.path) else {
            throw InstallError.missingManifest
        }
        let data = try Data(contentsOf: mURL)
        let manifest = try JSONDecoder()
            .decode(PluginManifest.self, from: data)

        let dest = pluginsDir
            .appendingPathComponent(manifest.id)
        if fm.fileExists(atPath: dest.path) {
            try fm.removeItem(at: dest)
        }
        try fm.moveItem(at: tmp, to: dest)
        PluginRegistry.shared.reload()
        return manifest
    }

    func uninstall(_ id: String) throws {
        let fm = FileManager.default
        let dest = pluginsDir.appendingPathComponent(id)
        if fm.fileExists(atPath: dest.path) {
            try fm.removeItem(at: dest)
        }
        PluginRegistry.shared.reload()
    }

    enum InstallError: LocalizedError {
        case badArchive
        case missingManifest
        var errorDescription: String? {
            switch self {
            case .badArchive:
                return "不是有效的 zip 归档"
            case .missingManifest:
                return "缺少 manifest.json"
            }
        }
    }
}
