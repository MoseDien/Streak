import Foundation
import UserNotifications

/// Production `NotificationScheduling` backed by `UNUserNotificationCenter`
/// (CLAUDE.md §15, §26). Stateless so it is trivially `Sendable`; views and
/// services depend on the protocol, never on this type directly.
struct SystemNotificationService: NotificationScheduling {
    private var center: UNUserNotificationCenter { UNUserNotificationCenter.current() }

    func authorizationStatus() async -> NotificationAuthorizationState {
        NotificationAuthorizationState(await center.notificationSettings().authorizationStatus)
    }

    func ensureAuthorized() async -> NotificationAuthorizationState {
        let current = await authorizationStatus()
        guard current == .notDetermined else { return current }
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted ? .authorized : .denied
        } catch {
            return .denied
        }
    }

    func scheduleReminder(for reminder: ProjectReminder) async throws {
        guard reminder.remindersEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.body
        content.sound = .default
        content.userInfo = [
            NotificationIdentifiers.projectIDKey: reminder.projectID.uuidString,
            NotificationIdentifiers.reminderIDKey: reminder.reminderID.uuidString
        ]

        var components = DateComponents()
        components.hour = reminder.reminderTime.hour
        components.minute = reminder.reminderTime.minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: NotificationIdentifiers.reminderIdentifier(for: reminder.projectID, reminderID: reminder.reminderID),
            content: content,
            trigger: trigger
        )
        try await center.add(request)
    }

    func cancelReminder(projectID: UUID, reminderID: UUID) async {
        center.removePendingNotificationRequests(
            withIdentifiers: [NotificationIdentifiers.reminderIdentifier(for: projectID, reminderID: reminderID)]
        )
    }

    func cancelAllReminders(forProject projectID: UUID) async {
        let pending = await center.pendingNotificationRequests()
        let identifiers = pending
            .compactMap { NotificationIdentifiers.projectID(from: $0.identifier) == projectID ? $0.identifier : nil }
        if !identifiers.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }

    func reconcile(reminders: [ProjectReminder]) async throws {
        // Cancel every existing project reminder, then re-create the active set.
        // Simple and idempotent (CLAUDE.md §15.5).
        let pending = await center.pendingNotificationRequests()
        let knownIdentifiers = pending
            .compactMap { NotificationIdentifiers.parseReminderIdentifier($0.identifier) != nil ? $0.identifier : nil }
        if !knownIdentifiers.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: knownIdentifiers)
        }
        for reminder in reminders where reminder.remindersEnabled {
            try await scheduleReminder(for: reminder)
        }
    }
}
