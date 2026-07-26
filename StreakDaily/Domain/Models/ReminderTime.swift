import Foundation

/// A wall-clock time of day (hour:minute) used to schedule a daily reminder.
///
/// The SwiftData model stores this as primitive `hour`/`minute` integers; the
/// domain works with this value type and converts at the boundary
/// (CLAUDE.md §9, §16.1).
struct ReminderTime: Hashable, Sendable {
    var hour: Int
    var minute: Int

    init(hour: Int = 20, minute: Int = 0) {
        self.hour = hour
        self.minute = minute
    }
}

extension ReminderTime {
    enum ValidationError: Error, Equatable, Sendable {
        case invalidHour(Int)
        case invalidMinute(Int)
    }

    /// Returns a validated reminder time, throwing if either component is out
    /// of range. Centralized so the limits can change in one place.
    static func validating(hour: Int, minute: Int) throws -> ReminderTime {
        guard (0 ... 23).contains(hour) else { throw ValidationError.invalidHour(hour) }
        guard (0 ... 59).contains(minute) else { throw ValidationError.invalidMinute(minute) }
        return ReminderTime(hour: hour, minute: minute)
    }
}
