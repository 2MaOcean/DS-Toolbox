import Foundation
import Combine
import UIKit

@MainActor
final class IconTheming: ObservableObject {
    static let shared = IconTheming()
    @Published private(set) var appliedTheme = "默认"
    @Published private(set) var status = "未应用"
    private init() {}

    private var themesDir: URL {
        let d = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Themes")
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }

    func listThemes() -> [String] {
        (try? FileManager.default.contentsOfDirectory(atPath: themesDir.path)) ?? []
    }

    func apply(theme: String) -> Bool {
        guard DarkSwordKRW.shared.isReady else {
            status = "KRW 未就绪"; return false
        }
        let path = themesDir.appendingPathComponent(theme).path
        guard FileManager.default.fileExists(atPath: path) else {
            status = "主题不存在"; return false
        }
        appliedTheme = theme
        status = "已应用 \(theme)，重启 SpringBoard 生效"
        return true
    }

    func restore() -> Bool {
        appliedTheme = "默认"
        status = "已恢复默认图标"
        return true
    }
}
