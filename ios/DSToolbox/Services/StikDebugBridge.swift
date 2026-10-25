import Foundation
import SwiftUI

/// 其他功能统一调用 StikDebug 的桥接层
@MainActor
final class StikDebugBridge: ObservableObject {
    static let shared = StikDebugBridge()
    private init() {}

    // MARK: - 应用启动

    /// 在 StikDebug 中启动应用（不附加调试器）
    func launchApp(bundleID: String) -> Bool {
        guard StikDebugProvider.shared.isInstalled else { return false }
        return StikDebugProvider.shared.launchApp(bundleID: bundleID)
    }

    /// 在 StikDebug 中启动应用并附加 JIT
    func launchAppWithJIT(bundleID: String) -> Bool {
        guard StikDebugProvider.shared.isInstalled else { return false }
        _ = StikDebugProvider.shared.openJIT(bundleID: bundleID)
        return true
    }

    // MARK: - 进程管理

    func killProcess(pid: Int) -> Bool {
        guard StikDebugProvider.shared.isInstalled else { return false }
        return StikDebugProvider.shared.killProcess(pid: pid)
    }

    // MARK: - 能力降级指引

    /// 文件管理：StikDebug 不支持，返回降级指引
    var fileManagerFallbackMessage: String {
        "StikDebug 不支持文件管理。请使用本 App 内置的文件浏览器，或越狱后使用 Filza。"
    }

    /// 系统监控：StikDebug 不支持，返回降级指引
    var systemMonitorFallbackMessage: String {
        "StikDebug 不提供系统监控。请使用本 App 内置的监控面板。"
    }

    /// 虚拟定位：StikDebug 支持，但需手动操作
    var locationFallbackMessage: String {
        "StikDebug 支持虚拟定位，请在 StikDebug 内使用 location 功能。"
    }
}
