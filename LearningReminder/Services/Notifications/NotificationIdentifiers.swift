import Foundation

/// Centralized notification identifiers (CLAUDE.md §15.3, §15.4).
enum NotificationIdentifiers {
    /// `userInfo` key holding the stable project UUID string.
    static let projectIDKey = "projectID"
    /// `userInfo` key holding the stable reminder UUID string.
    static let reminderIDKey = "reminderID"

    /// Prefix for deterministic per-reminder identifiers.
    private static let reminderPrefix = "project.daily-reminder."

    /// Deterministic reminder identifier for one reminder of a project
    /// (CLAUDE.md §15.4: `project.daily-reminder.<projectUUID>.<reminderUUID>`).
    static func reminderIdentifier(for projectID: UUID, reminderID: UUID) -> String {
        reminderPrefix + projectID.uuidString + "." + reminderID.uuidString
    }

    /// A parsed reminder identifier.
    struct ParsedReminderIdentifier: Equatable, Sendable {
        let projectID: UUID
        let reminderID: UUID
    }

    /// Parses a reminder identifier, returning `nil` for identifiers that are
    /// not project reminders.
    static func parseReminderIdentifier(_ identifier: String) -> ParsedReminderIdentifier? {
        guard identifier.hasPrefix(reminderPrefix) else { return nil }
        let suffix = identifier.dropFirst(reminderPrefix.count)
        let parts = suffix.split(separator: ".").map(String.init)
        guard parts.count == 2,
              let projectID = UUID(uuidString: parts[0]),
              let reminderID = UUID(uuidString: parts[1]) else { return nil }
        return ParsedReminderIdentifier(projectID: projectID, reminderID: reminderID)
    }

    /// Convenience used by reconcile's "is this one of ours?" filter and by
    /// cancel-all-for-project.
    static func projectID(from identifier: String) -> UUID? {
        parseReminderIdentifier(identifier)?.projectID
    }
}
