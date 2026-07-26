import Foundation
import UserNotifications

/// Handles notification delivery and response (CLAUDE.md §27).
///
/// Foreground notifications are presented as a banner + sound. Tapping opens
/// the app; the project ID is available in `userInfo` for future deep-link
/// routing. The Completed / Not Completed check-in actions are wired once daily
/// check-ins exist (Phase 3).
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Tap opens the app (default behavior). Project ID:
        // response.notification.request.content.userInfo[NotificationIdentifiers.projectIDKey]
        completionHandler()
    }
}
