import Foundation

enum JITBackend: String, CaseIterable, Identifiable {
    case jailbreak = "越狱环境 (ptrace)"
    case stikDebug = "StikDebug (idevice)"
    var id: String { rawValue }
}

struct JITResult {
    let success: Bool
    let message: String
}
