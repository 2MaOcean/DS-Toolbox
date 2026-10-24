import Foundation
import Combine

struct SigningCertificate: Identifiable, Codable, Hashable {
    var id: String { name }
    let name: String
    let p12Path: String
    let mobileprovisionPath: String
    let expireDate: Date?
}

@MainActor
final class CertificateStore: ObservableObject {
    static let shared = CertificateStore()
    @Published private(set) var certificates: [SigningCertificate] = []
    private let key = "ds.certificates"

    private init() { load() }
    func add(_ c: SigningCertificate) { certificates.removeAll { $0.name == c.name }; certificates.append(c); persist() }
    func remove(name: String) { certificates.removeAll { $0.name == name }; persist() }
    func removeAll() { certificates.removeAll(); persist() }

    private func load() {
        guard let d = UserDefaults.standard.data(forKey: key), let list = try? JSONDecoder().decode([SigningCertificate].self, from: d) else { return }
        certificates = list
    }
    private func persist() {
        if let d = try? JSONEncoder().encode(certificates) { UserDefaults.standard.set(d, forKey: key) }
    }
}
