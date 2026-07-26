import Foundation

/// Errors raised by project-management operations (CLAUDE.md §28).
enum ProjectError: Error, Equatable, Sendable {
    case projectNotFound
    case emptyTitle
    case invalidStatusTransition(from: ProjectStatus, to: ProjectStatus)
    case activeProjectRecommendationExceeded(currentCount: Int, recommendedMaximum: Int)
    case tooManyReminders(max: Int)
    case noReminderTimes
    case duplicateReminderTime
}
