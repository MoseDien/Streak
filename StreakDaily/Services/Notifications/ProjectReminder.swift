import Foundation

/// A stable, value-type description of one scheduled reminder that can safely
/// cross actor boundaries into the notification service (CLAUDE.md §15.2).
///
/// One `ProjectReminder` = one schedulable unit (one `UNCalendarNotificationTrigger`).
/// Never carries a live SwiftData object; only stable value data.
struct ProjectReminder: Sendable, Equatable, Identifiable {
    let projectID: UUID
    let reminderID: UUID
    let title: String
    let body: String
    let reminderTime: ReminderTime
    let remindersEnabled: Bool

    var id: UUID { reminderID }
}

extension ProjectReminder {
    /// Default body shown when a project has no daily note.
    static let defaultBody = "Time for your daily check-in."

    /// Builds one `ProjectReminder` per reminder entry of the project.
    /// Main-actor-isolated: it reads a `@Model`.
    static func reminders(for project: LearningProject) -> [ProjectReminder] {
        let body = project.dailyNote.isEmpty ? Self.defaultBody : project.dailyNote
        return (project.reminderEntries ?? []).map { entry in
            ProjectReminder(
                projectID: project.id,
                reminderID: entry.id,
                title: project.title,
                body: body,
                reminderTime: entry.time,
                remindersEnabled: project.remindersEnabled
            )
        }
    }
}
