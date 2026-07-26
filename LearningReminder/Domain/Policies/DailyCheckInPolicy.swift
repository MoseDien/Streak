import Foundation

/// Enforces the daily check-in invariants: results are immutable once
/// finalized, and future days cannot be finalized (CLAUDE.md §11, §14).
///
/// The policy operates on already-normalized `LocalDay` values so it stays
/// deterministic and free of any live clock or calendar dependency.
struct DailyCheckInPolicy: Sendable {
    /// Returns the reason finalization is not allowed, or `nil` if a check-in
    /// with `currentStatus` on `day` may be finalized relative to `today`.
    func finalizationError(
        status currentStatus: DailyCheckInStatus,
        on day: LocalDay,
        relativeTo today: LocalDay
    ) -> DailyCheckInError? {
        guard currentStatus == .pending else { return .alreadyFinalized }
        guard day <= today else { return .futureDate }
        return nil
    }

    /// The persisted daily status to assign for a finalized result.
    func status(for result: FinalDailyResult) -> DailyCheckInStatus {
        result.dailyStatus
    }
}
