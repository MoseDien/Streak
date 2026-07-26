import Foundation
@testable import StreakDaily

/// Records notification calls so project transitions can assert their
/// scheduling side-effects (CLAUDE.md §31.5).
@MainActor
final class MockNotificationService: NotificationScheduling {
    private(set) var scheduled: [ProjectReminder] = []
    private(set) var cancelledReminders: [(projectID: UUID, reminderID: UUID)] = []
    private(set) var cancelledAllForProject: [UUID] = []
    private(set) var reconciled: [[ProjectReminder]] = []
    private(set) var ensureAuthorizedCount = 0
    var stubbedAuthorization: NotificationAuthorizationState = .authorized

    func authorizationStatus() async -> NotificationAuthorizationState {
        stubbedAuthorization
    }

    func ensureAuthorized() async -> NotificationAuthorizationState {
        ensureAuthorizedCount += 1
        return stubbedAuthorization
    }

    func scheduleReminder(for reminder: ProjectReminder) async throws {
        scheduled.append(reminder)
    }

    func cancelReminder(projectID: UUID, reminderID: UUID) async {
        cancelledReminders.append((projectID, reminderID))
    }

    func cancelAllReminders(forProject projectID: UUID) async {
        cancelledAllForProject.append(projectID)
    }

    func reconcile(reminders: [ProjectReminder]) async throws {
        reconciled.append(reminders)
    }

    /// Clears recorded calls between assertions within a test.
    func reset() {
        scheduled.removeAll()
        cancelledReminders.removeAll()
        cancelledAllForProject.removeAll()
        reconciled.removeAll()
        ensureAuthorizedCount = 0
    }
}
