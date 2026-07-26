import Foundation

/// A user's final, immutable answer for a daily check-in (CLAUDE.md §11).
///
/// Used by the finalization operation. Once a check-in is finalized with one
/// of these values it can never be changed.
enum FinalDailyResult: Sendable, Equatable {
    case completed
    case notCompleted
}

extension FinalDailyResult {
    /// The persisted daily status that corresponds to this final result.
    var dailyStatus: DailyCheckInStatus {
        switch self {
        case .completed: return .completed
        case .notCompleted: return .notCompleted
        }
    }
}
