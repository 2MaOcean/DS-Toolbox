import Foundation
import UIKit
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func notifyDownloadFinished(fileName: String) {
        let content = UNMutableNotificationContent()
        content.title = "下载完成"
        content.body = fileName
        content.sound = .default
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil),
            withCompletionHandler: nil
        )
    }

    func notifyDownloadFailed(fileName: String, reason: String) {
        let content = UNMutableNotificationContent()
        content.title = "下载失败"
        content.body = "\(fileName)：\(reason)"
        content.sound = .default
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil),
            withCompletionHandler: nil
        )
    }

    @MainActor
    func clearBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}
