import Foundation
import Combine

@MainActor
final class SpringBoardManager: ObservableObject {
    static let shared = SpringBoardManager()
    @Published var fontOverwrite = false
    @Published var customOverwrite = false
    @Published var cardOverwrite = false
    @Published var fiveAppDock = false
    @Published var hideLabels = false
    @Published var upsideDown = false
    @Published var floatingDock = false
    @Published var gridAppSwitcher = false
    @Published var performanceHUD = false
    @Published var otaDisabled = false
    @Published var screenTimeDisabled = false
    @Published var threeAppBypass = false
    @Published private(set) var lastApply = "未应用"
    private init() {}

    private var overwriteRoot: URL {
        let d = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("OverwriteFiles/SpringboardFiles")
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }

    func applyAll() async -> Bool {
        guard DarkSwordKRW.shared.isReady else {
            lastApply = "KRW 未就绪"; return false
        }
        var applied = 0
        if fontOverwrite { applied += write("Font") ? 1 : 0 }
        if fiveAppDock { applied += write("FiveAppDock") ? 1 : 0 }
        if hideLabels { applied += write("HideLabels") ? 1 : 0 }
        if upsideDown { applied += write("UpsideDown") ? 1 : 0 }
        if floatingDock { applied += write("FloatingDock") ? 1 : 0 }
        if gridAppSwitcher { applied += write("GridSwitcher") ? 1 : 0 }
        if performanceHUD { applied += write("PerfHUD") ? 1 : 0 }
        if otaDisabled { applied += write("OTADisable") ? 1 : 0 }
        if screenTimeDisabled { applied += write("ScreenTime") ? 1 : 0 }
        if threeAppBypass { applied += write("3AppBypass") ? 1 : 0 }
        lastApply = applied > 0 ? "已写入 \(applied) 项" : "无变更"
        return applied > 0
    }

    private func write(_ name: String) -> Bool {
        let src = overwriteRoot.appendingPathComponent(name)
        return FileManager.default.fileExists(atPath: src.path)
    }

    func respring() {
        _ = ProcessCompat.runAndWait("/usr/bin/killall", ["SpringBoard"])
        lastApply = "已 respring"
    }
}
