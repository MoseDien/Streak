import Foundation
import SwiftData

/// SwiftData model for a long-lived learning project (CLAUDE.md §16.1).
@Model
final class LearningProject {
    var id: UUID = UUID()
    var title: String = ""
    var dailyNote: String = ""
    var statusRawValue: String = ProjectStatus.notStarted.rawValue
    var remindersEnabled: Bool = true
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    @Relationship(deleteRule: .cascade, inverse: \DailyCheckIn.project)
    var checkIns: [DailyCheckIn]? = []

    @Relationship(deleteRule: .cascade, inverse: \ReminderEntry.project)
    var reminderEntries: [ReminderEntry]? = []

    init(
        id: UUID = UUID(),
        title: String,
        dailyNote: String = "",
        status: ProjectStatus = .notStarted,
        remindersEnabled: Bool = true,
        createdAt: Date = Date.now,
        updatedAt: Date = Date.now
    ) {
        self.id = id
        self.title = title
        self.dailyNote = dailyNote
        self.statusRawValue = status.rawValue
        self.remindersEnabled = remindersEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension LearningProject {
    /// Safe accessor for the project status. Unknown persisted raw values fall
    /// back to `notStarted`.
    var status: ProjectStatus {
        get { ProjectStatus(rawValue: statusRawValue) ?? .notStarted }
        set { statusRawValue = newValue.rawValue }
    }

    /// The project's reminder times, sorted by clock time, as domain values.
    var reminderTimes: [ReminderTime] {
        (reminderEntries ?? [])
            .sorted { $0.hour == $1.hour ? $0.minute < $1.minute : $0.hour < $1.hour }
            .map(\.time)
    }
}
