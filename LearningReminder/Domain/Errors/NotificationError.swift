import Foundation

/// Errors raised by notification operations (CLAUDE.md §28).
enum NotificationError: Error, Equatable, Sendable {
    case permissionDenied
    case invalidReminderTime
    case schedulingFailed
}
