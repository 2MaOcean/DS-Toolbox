import Foundation

struct ImportedIPA: Identifiable, Hashable {
    let id: UUID
    let fileURL: URL
    let fileName: String
    let size: Int64
    let bundleID: String?
    let displayName: String?
    let version: String?
    let isEncrypted: Bool
}

enum InstallMethod: String, CaseIterable, Identifiable {
    case trollStore = "TrollStore"
    case itmsServices = "OTA 安装"
    case documentPicker = "系统分享"
    var id: String { rawValue }
}
