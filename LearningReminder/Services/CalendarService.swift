import Foundation

/// Abstracts calendar operations so business logic can be tested with fixed
/// calendars and time zones (CLAUDE.md §12, §31.4).
protocol CalendarProviding: Sendable {
    func startOfDay(for date: Date) -> Date
    func localDay(for date: Date) -> LocalDay
    func isDateInToday(_ date: Date) -> Bool
    func nextDay(after day: LocalDay) -> LocalDay
    func isSameDay(_ day1: LocalDay, _ day2: LocalDay) -> Bool
}

/// Abstracts the current instant for deterministic testing (CLAUDE.md §31.4).
protocol DateProviding: Sendable {
    var now: Date { get }
}

/// Default provider backed by the user's autoupdating current calendar and the
/// real system clock.
struct SystemCalendarProvider: CalendarProviding, DateProviding {
    private let calendar: Calendar = .autoupdatingCurrent

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

    var now: Date { Date.now }
}
