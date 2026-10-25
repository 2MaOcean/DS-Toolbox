import Foundation
import SwiftUI

@MainActor
final class StikDebugBridge: ObservableObject {
    static let shared = StikDebugBridge()
    private init() {}

    // MARK: - 应用启动

    func launchApp(bundleID: String) -> Bool {
        guard StikDebugProvider.shared.isInstalled else { return false }
        return StikDebugProvider.shared.launchApp(bundleID: bundleID)
    }

    func launchAppWithJIT(bundleID: String) -> Bool {
        guard StikDebugProvider.shared.isInstalled else { return false }
        return StikDebugProvider.shared.openJIT(bundleID: bundleID)
    }

    // MARK: - 进程管理

    func killProcess(pid: Int) -> Bool {
        guard StikDebugProvider.shared.isInstalled else { return false }
        return StikDebugProvider.shared.killProcess(pid: pid)
    }

    // MARK: - 统一执行入口（直接调用内置实现，无引导）

    func openFiles() {
        // 由 UI 层负责跳转，此方法预留给未来路由
    }

    func startSystemMonitor() {
        SystemMonitorService.shared.start()
    }
}
