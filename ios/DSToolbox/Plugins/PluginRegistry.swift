import Foundation
import Combine

final class PluginRegistry: ObservableObject {
    static let shared = PluginRegistry()

    @Published private(set) var plugins: [PluginManifest] = []

    private init() { reload() }

    private var dir: URL {
        let d = FileManager.default
        let u = d.urls(for: .documentDirectory,
                       in: .userDomainMask)[0]
        return u.appendingPathComponent("Plugins")
    }

    func reload() {
        let fm = FileManager.default
        guard let list = try? fm.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: nil) else {
            plugins = []
            return
        }
        var out: [PluginManifest] = []
        for e in list where e.hasDirectoryPath {
            if e.lastPathComponent.hasPrefix("__tmp_") {
                continue
            }
            let m = e.appendingPathComponent("manifest.json")
            guard let data = try? Data(contentsOf: m),
                  let p = try? JSONDecoder()
                    .decode(PluginManifest.self, from: data)
            else { continue }
            out.append(p)
        }
        plugins = out.sorted { $0.id < $1.id }
    }

    func plugin(id: String) -> PluginManifest? {
        plugins.first { $0.id == id }
    }

    func rootURL(of id: String) -> URL {
        dir.appendingPathComponent(id)
    }
}
