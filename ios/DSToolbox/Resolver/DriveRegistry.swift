import Foundation
final class DriveRegistry {
    let adapters: [CloudDriveAdapter]
    init(adapters: [CloudDriveAdapter]) { self.adapters = adapters }
    func adapter(for url: URL) -> CloudDriveAdapter? { adapters.first { $0.canHandle(url) } }
}
