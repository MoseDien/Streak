import Foundation

/// Validates transitions between ``ProjectStatus`` values (CLAUDE.md §7).
///
/// Status assignment must never happen directly from a view; it goes through a
/// service that consults this policy.
struct ProjectStatusTransitionPolicy: Sendable {
    /// Returns `true` if a project may move from `origin` to `destination`.
    ///
    /// Re-asserting the current status is treated as an allowed no-op so that
    /// idempotent service calls do not fail spuriously.
    func canTransition(from origin: ProjectStatus, to destination: ProjectStatus) -> Bool {
        if origin == destination { return true }

        switch destination {
        case .notStarted:
            return false
        case .inProgress:
            return origin == .notStarted || origin == .paused
        case .paused:
            return origin == .inProgress
        case .failed:
            return origin == .notStarted || origin == .inProgress || origin == .paused
        case .completed:
            return origin == .inProgress || origin == .paused
        }
    }

    /// The distinct statuses a project in `status` may move to, excluding its
    /// current status. Used by the UI to decide which action buttons to show.
    func availableTransitions(from status: ProjectStatus) -> [ProjectStatus] {
        ProjectStatus.allCases.filter { $0 != status && canTransition(from: status, to: $0) }
    }
}
