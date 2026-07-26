import Foundation
@testable import StreakDaily

/// A calendar/date provider with fixed values for deterministic tests
/// (CLAUDE.md §31.4).
struct FixedCalendarProvider: CalendarProviding, DateProviding {
    let calendar: Calendar
    let now: Date

    func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    func localDay(for date: Date) -> LocalDay {
        LocalDay(startOfDay: calendar.startOfDay(for: date))
    }

    func isDateInToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    func nextDay(after day: LocalDay) -> LocalDay {
        let next = calendar.date(byAdding: .day, value: 1, to: day.startOfDay) ?? day.startOfDay
        return LocalDay(startOfDay: next)
    }

    func isSameDay(_ day1: LocalDay, _ day2: LocalDay) -> Bool {
        day1 == day2
    }
}
