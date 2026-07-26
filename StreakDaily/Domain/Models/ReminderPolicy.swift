import Foundation

/// Centralized reminder limits (CLAUDE.md §8 style — keep policy in one place).
enum ReminderPolicy {
    /// Maximum number of daily reminders a single project may have.
    static let maxPerProject = 3
}
