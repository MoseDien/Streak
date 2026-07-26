import Foundation
import SwiftData

/// SwiftData model for a single daily reminder owned by a project
/// (CLAUDE.md §16). A project owns zero or more entries.
@Model
final class ReminderEntry {
    var id: UUID = UUID()
    var hour: Int = 20
    var minute: Int = 0

    var project: LearningProject?

    init(id: UUID = UUID(), hour: Int = 20, minute: Int = 0, project: LearningProject) {
        self.id = id
        self.hour = hour
        self.minute = minute
        self.project = project
    }
}

extension ReminderEntry {
    /// The reminder time as a domain value type.
    var time: ReminderTime {
        get { ReminderTime(hour: hour, minute: minute) }
        set {
            hour = newValue.hour
            minute = newValue.minute
        }
    }
}
