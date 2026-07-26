import Foundation

/// Errors raised by daily check-in operations (CLAUDE.md §11, §28).
enum DailyCheckInError: Error, Equatable, Sendable {
    /// The check-in has already been finalized and is immutable.
    case alreadyFinalized
    /// The requested date is in the future and cannot be finalized.
    case futureDate
    /// The project is not in a state that permits check-ins.
    case invalidProjectState
    /// No project was found for the given identifier.
    case projectNotFound
}
