import Foundation
import Combine
final class DownloadOptionsStore: ObservableObject {
    static let shared = DownloadOptionsStore()
    @Published var global: DownloadOptions
    @Published private(set) var perHost: [String: DownloadOptions]
    private let globalKey = "ds.download.options.global"
    private let perHostKey = "ds.download.options.perHost"
    private init() {
        global = Self.load(from: globalKey) ?? .default
        perHost = Self.load(from: perHostKey) ?? [:]
    }
    func options(for host: String) -> DownloadOptions {
        let h = host.lowercased()
        if let exact = perHost[h] { return exact }
        if let sub = perHost.first(where: { h.hasSuffix("." + $0.key) }) { return sub.value }
        return global
    }
    func setHostOptions(_ options: DownloadOptions, for host: String) { perHost[host.lowercased()] = options; persist() }
    func removeHostOptions(_ host: String) { perHost.removeValue(forKey: host.lowercased()); persist() }
    func saveGlobal() { persist() }
    private func persist() {
        if let d = try? JSONEncoder().encode(global) { UserDefaults.standard.set(d, forKey: globalKey) }
        if let d = try? JSONEncoder().encode(perHost) { UserDefaults.standard.set(d, forKey: perHostKey) }
    }
    private static func load<T: Decodable>(from key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
