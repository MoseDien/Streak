import Foundation
import SwiftData
import UserNotifications

/// The app composition root (CLAUDE.md §26). Builds the persistence container,
/// the notification service, and the services that depend on its main context.
@MainActor
final class AppDependencies {
    let container: ModelContainer
    let projectService: ProjectService
    let notificationService: SystemNotificationService
    let notificationDelegate: NotificationDelegate
    let reconciliationService: AppReconciliationService

    init() throws {
        let container = try ModelContainerFactory.makeContainer()
        self.container = container
        let notifications = SystemNotificationService()
        self.notificationService = notifications
        self.projectService = ProjectService(context: container.mainContext, notificationService: notifications)
        self.notificationDelegate = NotificationDelegate()
        self.reconciliationService = AppReconciliationService(context: container.mainContext, notificationService: notifications)

        // Install the delegate early so notification responses are handled
        // (CLAUDE.md §27).
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }
}
