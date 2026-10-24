import Foundation

enum CertificateValidator {
    static func isExpired(_ path: String) -> Bool {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let mod = attrs[.modificationDate] as? Date else { return true }
        return Date().timeIntervalSince(mod) > 365 * 24 * 3600
    }
    static func expired(_ cert: SigningCertificate) -> Bool {
        if let d = cert.expireDate { return d < Date() }
        return isExpired(cert.mobileprovisionPath)
    }
}
