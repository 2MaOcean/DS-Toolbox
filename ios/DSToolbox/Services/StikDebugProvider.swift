import Foundation
import UIKit

final class StikDebugProvider {
    static let shared = StikDebugProvider()
    private init() {}

    // MARK: - 可用性检测

    var isInstalled: Bool {
        if let u = URL(string: "stikjit://"), UIApplication.shared.canOpenURL(u) { return true }
        let paths = ["/var/containers/Bundle/Application/.stikjit", "/Applications/StikJIT.app"]
        return paths.contains { FileManager.default.fileExists(atPath: $0) }
    }

    // MARK: - 统一调用入口

    @MainActor
    @discardableResult
    func openJIT(bundleID: String? = nil, pid: Int? = nil, scriptData: String? = nil, scriptName: String? = nil) -> Bool {
        var comps = URLComponents()
        comps.scheme = "stikjit"
        comps.host = "enable-jit"
        var items: [URLQueryItem] = []
        if let id = bundleID { items.append(.init(name: "bundle-id", value: id)) }
        if let p = pid { items.append(.init(name: "pid", value: String(p))) }
        if let sd = scriptData { items.append(.init(name: "script-data", value: sd)) }
        if let sn = scriptName { items.append(.init(name: "script-name", value: sn)) }
        comps.queryItems = items
        return open(comps.url)
    }

    @MainActor
    @discardableResult
    func launchApp(bundleID: String) -> Bool {
        var comps = URLComponents()
        comps.scheme = "stikjit"
        comps.host = "launch-app"
        comps.queryItems = [.init(name: "bundle-id", value: bundleID)]
        return open(comps.url)
    }

    @MainActor
    @discardableResult
    func killProcess(pid: Int) -> Bool {
        var comps = URLComponents()
        comps.scheme = "stikjit"
        comps.host = "kill-process"
        comps.queryItems = [.init(name: "pid", value: String(pid))]
        return open(comps.url)
    }

    // MARK: - 私有

    @MainActor
    private func open(_ url: URL?) -> Bool {
        guard let u = url, UIApplication.shared.canOpenURL(u) else { return false }
        UIApplication.shared.open(u)
        return true
    }
}
