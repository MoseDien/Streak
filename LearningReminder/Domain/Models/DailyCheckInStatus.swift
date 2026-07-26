import Foundation

/// The result of a single project on a single local calendar day
/// (CLAUDE.md §10).
enum DailyCheckInStatus: String, Codable, CaseIterable, Sendable {
    /// No final answer has been submitted for this date yet.
    case pending
    /// The user confirmed the activity was completed.
    case completed
    /// The user confirmed the activity was not completed.
    case notCompleted
}

extension DailyCheckInStatus {
    /// Only `completed` and `notCompleted` are final, immutable results.
    var isFinal: Bool {
        self == .completed || self == .notCompleted
    }
}
