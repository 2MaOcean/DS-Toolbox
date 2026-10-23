import Foundation
import Combine
final class CertificateStore: ObservableObject {
    static let shared = CertificateStore(); @Published private(set) var certificates: [SigningCertificate] = []
    var storeDirectory: URL { let d = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("IPACerts"); try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true); return d }
    private init() { if let d = UserDefaults.standard.data(forKey: "ipa.certificates"), let l = try? JSONDecoder().decode([SigningCertificate].self, from: d) { certificates = l } }
    func importCertificate(p12: URL, provision: URL, password: String, displayName: String) throws {
        let uuid = UUID().uuidString; let dp = storeDirectory.appendingPathComponent("\(uuid).p12"); let dv = storeDirectory.appendingPathComponent("\(uuid).mobileprovision")
        try? FileManager.default.copyItem(at: p12, to: dp); try? FileManager.default.copyItem(at: provision, to: dv)
        let cert = SigningCertificate(uuid: uuid, displayName: displayName, p12Path: dp.path, provisionPath: dv.path, p12Password: password, expiresAt: nil, teamID: nil, isFreeAccount: true)
        certificates.append(cert); if let d = try? JSONEncoder().encode(certificates) { UserDefaults.standard.set(d, forKey: "ipa.certificates") }
    }
    func delete(_ cert: SigningCertificate) { try? FileManager.default.removeItem(atPath: cert.p12Path); try? FileManager.default.removeItem(atPath: cert.provisionPath); certificates.removeAll { $0.uuid == cert.uuid } }
}
