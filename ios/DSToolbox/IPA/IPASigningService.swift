import Foundation
import ZIPFoundation
final class IPASigningService {
    static let shared = IPASigningService(); private init() {}
    func prepareForSigning(ipa: URL, certificate: SigningCertificate, outputDirectory: URL) async throws -> URL {
        let fm = FileManager.default; let work = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString); try fm.createDirectory(at: work, withIntermediateDirectories: true)
        try fm.unzipItem(at: ipa, to: work)
        let payload = work.appendingPathComponent("Payload")
        if let apps = try? fm.contentsOfDirectory(at: payload, includingPropertiesForKeys: nil), let provData = try? Data(contentsOf: URL(fileURLWithPath: certificate.provisionPath)) {
            for app in apps where app.pathExtension == "app" { try? provData.write(to: app.appendingPathComponent("embedded.mobileprovision")) }
        }
        let out = outputDirectory.appendingPathComponent("prepared.ipa"); try? fm.removeItem(at: out); try fm.zipItem(at: work, to: out)
        try? fm.removeItem(at: work); return out
    }
}
