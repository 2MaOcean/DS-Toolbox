import Foundation

struct PluginManifest: Codable, Identifiable {
    let id: String
    let name: String
    let version: String
    let author: String
    let description: String
    let type: PluginKind
    let entry: PluginEntry?
    let slots: [PluginSlot]?

    enum PluginKind: String, Codable {
        case backend, frontend, hybrid
    }
}

struct PluginEntry: Codable {
    let backend: String?
    let frontend: String?
    let hybrid: String?
}

struct PluginSlot: Codable, Identifiable {
    var id: String { slot + "|" + file }
    let slot: String
    let file: String
}
