import Foundation
import Combine

@MainActor
final class StikDebugService: ObservableObject {
    static let shared = StikDebugService()
    @Published private(set) var canEnableJIT = false
    @Published private(set) var isAttached = false
    private init() { refresh() }

    func refresh() {
        canEnableJIT = TrollStoreService.shared.isInstalled
            || FileManager.default.fileExists(atPath: "/var/jb")
    }
    func attach(bundleID: String) { isAttached = true }
    func detach() { isAttached = false }
}
