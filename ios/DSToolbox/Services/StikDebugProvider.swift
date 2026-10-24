import Foundation
import UIKit

final class StikDebugProvider {
    static let shared = StikDebugProvider()
    private init() {}

    /// StikDebug 注册的 URL Scheme
    private let candidates: [String] = [
        "stikdebug://",
        "stikjit://",
        "stikdebug://open"
    ]

    var isInstalled: Bool {
        for s in candidates {
            if let u = URL(string: s), UIApplication.shared.canOpenURL(u) { return true }
        }
        // 越狱环境用 bundle ID 检测
        let paths = [
            "/var/containers/Bundle/Application/.stikdebug",
            "/Applications/StikDebug.app"
        ]
        for p in paths where FileManager.default.fileExists(atPath: p) { return true }
        return false
    }

    @MainActor
    func open() -> Bool {
        for s in candidates {
            if let u = URL(string: s), UIApplication.shared.canOpenURL(u) {
                UIApplication.shared.open(u)
                return true
            }
        }
        return false
    }

    func enableJIT(bundleID: String) -> JITResult {
        // 无法通过 URL Scheme 直接传参启用 JIT，需要用户手动操作
        if !isInstalled {
            return JITResult(success: false, message: "未安装 StikDebug，请先安装后再使用")
        }
        return JITResult(success: false, message: "请在打开的 StikDebug 中手动启用 \(bundleID) 的 JIT")
    }
}
