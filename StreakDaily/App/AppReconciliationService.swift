import Foundation
import SwiftData

/// Keeps pending notifications aligned with persisted active projects
/// (CLAUDE.md §15.5, §18.5). Run on launch and whenever the app returns to the
/// foreground.
@MainActor
final class AppReconciliationService {
    private let context: ModelContext
    private let notificationService: any NotificationScheduling

    init(context: ModelContext, notificationService: any NotificationScheduling) {
        self.context = context
        self.notificationService = notificationService
    }

    func reconcile() async {
        let activeRaw = ProjectStatus.inProgress.rawValue
        let projects = (try? context.fetch(FetchDescriptor<LearningProject>(
            predicate: #Predicate { $0.statusRawValue == activeRaw }
        ))) ?? []
        let reminders = projects.flatMap { ProjectReminder.reminders(for: $0) }
        try? await notificationService.reconcile(reminders: reminders)
    }
}
