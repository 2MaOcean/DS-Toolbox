import Foundation
import Combine

@MainActor
final class SpringBoardTweaks: ObservableObject {
    static let shared = SpringBoardTweaks()
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
    private init() {}

    func apply() async -> Bool {
        guard DarkSwordKRW.shared.isReady else { return false }
        try? await Task.sleep(nanoseconds: 600_000_000)
        return true
    }

    func respring() {
        // 越狱环境可 killall SpringBoard；沙盒环境调用私有 API
    }
}
