import Foundation
import SwiftUI

@MainActor
final class JITManager: ObservableObject {
    static let shared = JITManager()
    @Published var pendingBundleID: String?
    @Published var showPicker = false
    @Published var lastResult: JITResult?
    private init() {}

    func requestEnable(bundleID: String) {
        pendingBundleID = bundleID
        showPicker = true
    }

    func confirm(backend: JITBackend) -> JITResult {
        guard let bid = pendingBundleID else {
            return JITResult(success: false, message: "无目标应用")
        }
        defer { pendingBundleID = nil; showPicker = false }
        switch backend {
        case .jailbreak:
            guard let pid = JailbreakJITProvider.findPID(bundleID: bid) else {
                return JITResult(success: false, message: "未找到进程 \(bid)")
            }
            return JailbreakJITProvider.enable(pid: pid)
        case .stikDebug:
            let r = StikDebugProvider.shared.enableJIT(bundleID: bid)
            _ = StikDebugProvider.shared.open()
            return r
        }
    }
}
