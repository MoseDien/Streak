import Foundation

/// Lifecycle status of a long-lived learning project (CLAUDE.md §6).
///
/// This represents the long-term state of a project, not whether a particular
/// day was completed. See ``DailyCheckInStatus`` for daily results.
enum ProjectStatus: String, Codable, CaseIterable, Sendable {
    case notStarted
    case inProgress
    case paused
    case failed
    case completed
}

extension ProjectStatus {
    /// Whether the project is actively worked on and therefore receives daily
    /// reminders. Only `inProgress` qualifies (CLAUDE.md §15).
    var receivesDailyReminders: Bool {
        self == .inProgress
    }

    /// Terminal project states cannot return to an active state
    /// (CLAUDE.md §7).
    var isTerminal: Bool {
        self == .failed || self == .completed
    }
}
