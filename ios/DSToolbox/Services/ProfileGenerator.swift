import Foundation

enum ProfileOption: String, CaseIterable, Identifiable {
    case hideApp = "隐藏应用"
    case lockScreenFootnote = "锁屏脚注"
    case webClip = "WebClip 生成"
    case delayUpdates = "延迟系统更新"
    case forceWiFiAssist = "强制 WiFi 助理"
    var id: String { rawValue }
}

final class ProfileGenerator {
    static let shared = ProfileGenerator()
    private init() {}

    func generate(options: [ProfileOption], footnote: String? = nil) -> Data? {
        var payloads: [[String: Any]] = []
        for option in options {
            switch option {
            case .lockScreenFootnote:
                if let text = footnote, !text.isEmpty {
                    payloads.append([
                        "PayloadType": "com.apple.shareddeviceconfiguration",
                        "PayloadIdentifier": "com.ds.locknote.\(UUID().uuidString)",
                        "PayloadVersion": 1,
                        "PayloadUUID": UUID().uuidString,
                        "PayloadDisplayName": "锁屏脚注",
                        "LockScreenFootnote": text
                    ])
                }
            case .delayUpdates:
                payloads.append([
                    "PayloadType": "com.apple.applicationaccess",
                    "PayloadIdentifier": "com.ds.delay.\(UUID().uuidString)",
                    "PayloadVersion": 1,
                    "PayloadUUID": UUID().uuidString,
                    "PayloadDisplayName": "延迟系统更新",
                    "forceDelayedSoftwareUpdates": true
                ])
            case .forceWiFiAssist:
                payloads.append([
                    "PayloadType": "com.apple.applicationaccess",
                    "PayloadIdentifier": "com.ds.wifi.\(UUID().uuidString)",
                    "PayloadVersion": 1,
                    "PayloadUUID": UUID().uuidString,
                    "PayloadDisplayName": "WiFi 助理",
                    "allowWiFiAssist": true
                ])
            case .hideApp, .webClip:
                continue
            }
        }
        guard !payloads.isEmpty else { return nil }
        let profile: [String: Any] = [
            "PayloadType": "Configuration",
            "PayloadIdentifier": "com.ds.profile.\(UUID().uuidString)",
            "PayloadVersion": 1,
            "PayloadUUID": UUID().uuidString,
            "PayloadDisplayName": "DS工具箱配置",
            "PayloadContent": payloads
        ]
        return try? PropertyListSerialization.data(fromPropertyList: profile, format: .xml, options: 0)
    }
}
