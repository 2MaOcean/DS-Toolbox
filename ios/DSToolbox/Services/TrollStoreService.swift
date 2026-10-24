import Foundation
import UIKit

final class TrollStoreService {
    static let shared = TrollStoreService()
    private init() {}
    
    var isInstalled: Bool {
        guard let url = URL(string: "apple-magnifier://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
    
    func openTrollStore() -> Bool {
        guard let url = URL(string: "apple-magnifier://"), UIApplication.shared.canOpenURL(url) else { return false }
        UIApplication.shared.open(url)
        return true
    }
}
