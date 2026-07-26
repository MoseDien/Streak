import Foundation

/// Centralizes daily check-in resolution and immutable finalization
/// (CLAUDE.md §11, §13, §18.2). Views must not mutate check-ins directly.
@MainActor
protocol DailyCheckInManaging {
    /// Finds the check-in for `projectID` on the local day of `date`, creating
    /// a `pending` one if none exists and the project is active. Returns the
    /// existing record rather than duplicating when one already exists.
    func checkIn(for projectID: UUID, on date: Date) throws -> DailyCheckIn

    /// Finalizes the check-in for `projectID` on the local day of `date`. The
    /// result is immutable once set (CLAUDE.md §11).
    func finalize(projectID: UUID, on date: Date, result: FinalDailyResult) throws
}
