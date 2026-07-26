import Foundation

/// Abstracts notification scheduling so it can be mocked in tests
/// (CLAUDE.md §15, §18.3, §26).
protocol NotificationScheduling: Sendable {
    func authorizationStatus() async -> NotificationAuthorizationState

    /// Requests authorization only when currently `notDetermined`. Call this in
    /// response to an understandable user action (CLAUDE.md §15.1).
    func ensureAuthorized() async -> NotificationAuthorizationState

    func scheduleReminder(for reminder: ProjectReminder) async throws
    func cancelReminder(projectID: UUID, reminderID: UUID) async
    func cancelAllReminders(forProject projectID: UUID) async
    func reconcile(reminders: [ProjectReminder]) async throws
}
