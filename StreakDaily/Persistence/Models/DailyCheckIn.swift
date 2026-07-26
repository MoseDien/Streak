import Foundation
import SwiftData

/// SwiftData model for a single project's result on a single local calendar
/// day (CLAUDE.md §16.2).
///
/// `localDay` stores a normalized local start-of-day date.
@Model
final class DailyCheckIn {
    var id: UUID = UUID()
    var localDay: Date = Date.now
    var statusRawValue: String = DailyCheckInStatus.pending.rawValue
    var createdAt: Date = Date.now
    var finalizedAt: Date?

    var project: LearningProject?

    init(
        id: UUID = UUID(),
        localDay: Date,
        status: DailyCheckInStatus = .pending,
        createdAt: Date = Date.now,
        finalizedAt: Date? = nil,
        project: LearningProject
    ) {
        self.id = id
        self.localDay = localDay
        self.statusRawValue = status.rawValue
        self.createdAt = createdAt
        self.finalizedAt = finalizedAt
        self.project = project
    }
}

extension DailyCheckIn {
    /// Safe accessor for the daily status. Unknown persisted raw values fall
    /// back to `pending`.
    var status: DailyCheckInStatus {
        get { DailyCheckInStatus(rawValue: statusRawValue) ?? .pending }
        set { statusRawValue = newValue.rawValue }
    }
}
