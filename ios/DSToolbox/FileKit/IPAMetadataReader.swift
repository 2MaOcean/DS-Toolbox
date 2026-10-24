import Foundation
import ZIPFoundation

struct IPAMetadata {
    let bundleID: String
    let name: String
    let version: String
    let isEncrypted: Bool
}

enum IPAMetadataReader {
    static func read(from ipa: URL) -> IPAMetadata? {
        guard let archive = try? Archive(url: ipa, accessMode: .read) else { return nil }
        guard let infoEntry = archive.first(where: { $0.path.contains("Payload/") && $0.path.hasSuffix(".app/Info.plist") }) else { return nil }
        var data = Data()
        _ = try? archive.extract(infoEntry) { data.append($0) }
        guard let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else { return nil }
        let bundleID = plist["CFBundleIdentifier"] as? String ?? ""
        let name = (plist["CFBundleDisplayName"] as? String) ?? (plist["CFBundleName"] as? String) ?? ""
        let version = plist["CFBundleShortVersionString"] as? String ?? ""
        let executable = plist["CFBundleExecutable"] as? String ?? ""
        let binPath = infoEntry.path.replacingOccurrences(of: "Info.plist", with: executable)
        var encrypted = false
        if let binEntry = archive.first(where: { $0.path == binPath }) {
            var binData = Data()
            _ = try? archive.extract(binEntry) { binData.append($0) }
            encrypted = isFairPlayEncrypted(binData)
        }
        return IPAMetadata(bundleID: bundleID, name: name, version: version, isEncrypted: encrypted)
    }

    private static func isFairPlayEncrypted(_ data: Data) -> Bool {
        guard data.count > 32 else { return false }
        let magic = data.withUnsafeBytes { $0.load(as: UInt32.self) }
        guard magic == 0xFEEDFACF || magic == 0xFEEDFACE else { return false }
        var offset = 32
        while offset + 8 <= data.count {
            let cmd = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }
            let size = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 4, as: UInt32.self) }
            if cmd == 0x21, size >= 20, offset + 20 <= data.count {
                let cryptid = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 16, as: UInt32.self) }
                return cryptid != 0
            }
            if size == 0 { break }
            offset += Int(size)
        }
        return false
    }
}
