import Foundation

enum SigningType: String {
    case developer = "个人开发者证书"
    case enterprise = "企业证书"
    case appStore = "App Store"
    case trollStore = "TrollStore / 越狱"
    case unknown = "未知"
}

final class SigningTypeDetector {
    static let shared = SigningTypeDetector()
    private(set) lazy var type: SigningType = detect()
    private init() {}

    private func detect() -> SigningType {
        if FileManager.default.fileExists(atPath: "/var/jb")
            || FileManager.default.fileExists(atPath: "/var/containers/Bundle/Application/.trollstore") {
            return .trollStore
        }
        guard let path = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let start = data.range(of: Data("<?xml".utf8)),
              let end = data.range(of: Data("</plist>".utf8)) else {
            return .unknown
        }
        let plistData = data.subdata(in: start.lowerBound..<end.upperBound)
        guard let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
            return .unknown
        }
        if plist["ProvisionsAllDevices"] as? Bool == true { return .enterprise }
        if let devices = plist["ProvisionedDevices"] as? [String], !devices.isEmpty { return .developer }
        return .appStore
    }
}
