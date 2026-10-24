import Foundation
import ZIPFoundation

struct IPAMetadata {
    let bundleID: String
    let name: String
    let version: String
    let buildNumber: String
    let isEncrypted: Bool
    let iconData: Data?
}

enum IPAMetadataReader {
    static func read(from ipa: URL) -> IPAMetadata? {
        guard let archive = try? Archive(url: ipa, accessMode: .read) else { return nil }
        guard let entry = archive.first(where: { $0.path.hasSuffix(".app/Info.plist") && $0.path.components(separatedBy: "/").count == 3 }) else { return nil }
        var data = Data()
        guard (try? archive.extract(entry, consumer: { data.append($0) })) != nil else { return nil }
        return parse(data)
    }
    
    private static func parse(_ data: Data) -> IPAMetadata? {
        guard let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else { return nil }
        return IPAMetadata(
            bundleID: plist["CFBundleIdentifier"] as? String ?? "unknown",
            name: (plist["CFBundleDisplayName"] as? String) ?? (plist["CFBundleName"] as? String) ?? "unknown",
            version: plist["CFBundleShortVersionString"] as? String ?? "1.0",
            buildNumber: plist["CFBundleVersion"] as? String ?? "1",
            isEncrypted: plist["CryptID"] != nil,
            iconData: nil
        )
    }
}
