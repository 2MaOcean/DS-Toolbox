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
            // 本地 ptrace（越狱环境可用）
            guard let pid = JailbreakJITProvider.findPID(bundleID: bid) else {
                return JITResult(success: false, message: "未找到进程 \(bid)")
            }
            return JailbreakJITProvider.enable(pid: pid)

        case .stikDebug:
            // 统一委托给 StikDebug
            guard StikDebugProvider.shared.isInstalled else {
                return JITResult(success: false, message: "未安装 StikDebug，请先安装")
            }
            let ok = StikDebugProvider.shared.openJIT(bundleID: bid)
            return JITResult(
                success: ok,
                message: ok ? "已唤起 StikDebug 启用 JIT：\(bid)" : "无法唤起 StikDebug"
            )
        }
    }
}
