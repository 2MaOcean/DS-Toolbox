import Foundation
import Combine

@MainActor
final class ToolboxEnvironment: ObservableObject {
    static let shared = ToolboxEnvironment()

    @Published var currentKind: DriveKind = .baidu
    @Published var credential: DriveCredential?

    let registry: DriveRegistry
    let queue: DownloadQueue
    let history: DownloadHistory

    @AppStorage("ds.dualPaneEnabled") var dualPaneEnabled: Bool = false

    private init() {
        self.registry = DriveRegistry(adapters: [
            BaiduAdapter(), QuarkAdapter(), GuangyaAdapter(), CMCCAdapter(), TelecomAdapter()
        ])
        self.queue = DownloadQueue.shared
        self.history = DownloadHistory.shared
        self.credential = CredentialStore.shared.load(kind: .baidu)
    }

    var currentAdapter: CloudDriveAdapter? {
        registry.adapters.first { $0.kind == currentKind }
    }

    func selectKind(_ kind: DriveKind) {
        currentKind = kind
        credential = CredentialStore.shared.load(kind: kind)
    }
}
