import Testing
import Foundation
@testable import StreakDaily

@Suite("Calendar normalization (CLAUDE.md §12, §31.4)")
struct CalendarProviderTests {
    private func calendar(in timeZoneIdentifier: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .current
        return calendar
    }

    private func provider(for calendar: Calendar) -> FixedCalendarProvider {
        FixedCalendarProvider(calendar: calendar, now: Date(timeIntervalSince1970: 0))
    }

    @Test("start of day normalizes to local midnight")
    func startOfDayNormalization() throws {
        let calendar = self.calendar(in: "UTC")
        let provider = provider(for: calendar)
        let afternoon = try #require(calendar.date(from: DateComponents(
            year: 2024, month: 3, day: 10, hour: 14, minute: 30
        )))

        let day = provider.localDay(for: afternoon)
        let components = calendar.dateComponents([.month, .day, .hour, .minute], from: day.startOfDay)

        #expect(components.month == 3)
        #expect(components.day == 10)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
    }

    @Test("times on the same calendar day share a start of day")
    func sameDaySharesStartOfDay() throws {
        let calendar = self.calendar(in: "UTC")
        let provider = provider(for: calendar)
        let morning = try #require(calendar.date(from: DateComponents(year: 2024, month: 3, day: 10, hour: 6, minute: 0)))
        let evening = try #require(calendar.date(from: DateComponents(year: 2024, month: 3, day: 10, hour: 23, minute: 59)))

        #expect(provider.localDay(for: morning) == provider.localDay(for: evening))
    }

    @Test("start of day survives a spring-forward daylight-saving transition")
    func startOfDayAcrossDST() throws {
        let calendar = self.calendar(in: "America/New_York")
        let provider = provider(for: calendar)
        let afternoon = try #require(calendar.date(from: DateComponents(
            year: 2024, month: 3, day: 10, hour: 14, minute: 30
        )))

        let day = provider.localDay(for: afternoon)
        let components = calendar.dateComponents([.month, .day, .hour], from: day.startOfDay)
        #expect(components.month == 3)
        #expect(components.day == 10)
        #expect(components.hour == 0)

        let nextDay = provider.nextDay(after: day)
        let nextComponents = calendar.dateComponents([.month, .day], from: nextDay.startOfDay)
        #expect(nextComponents.month == 3)
        #expect(nextComponents.day == 11)
    }

    @Test("the same instant can land on different local days across time zones")
    func timezoneDifference() throws {
        let utcCalendar = calendar(in: "UTC")
        let tokyoCalendar = calendar(in: "Asia/Tokyo")
        let utcProvider = provider(for: utcCalendar)
        let tokyoProvider = provider(for: tokyoCalendar)

        // 2024-03-10 23:30 UTC is already 2024-03-11 in Tokyo (UTC+9).
        let instant = try #require(utcCalendar.date(from: DateComponents(
            year: 2024, month: 3, day: 10, hour: 23, minute: 30
        )))

        let utcDay = utcProvider.localDay(for: instant)
        let tokyoDay = tokyoProvider.localDay(for: instant)

        #expect(!utcProvider.isSameDay(utcDay, tokyoDay))
        #expect(utcDay < tokyoDay)
    }

    @Test("midnight is the boundary between two local days")
    func midnightBoundary() throws {
        let calendar = self.calendar(in: "UTC")
        let provider = provider(for: calendar)
        let justBeforeMidnight = try #require(calendar.date(from: DateComponents(
            year: 2024, month: 3, day: 10, hour: 23, minute: 59, second: 59
        )))
        let midnight = try #require(calendar.date(from: DateComponents(
            year: 2024, month: 3, day: 11, hour: 0, minute: 0
        )))

        let lateDay = provider.localDay(for: justBeforeMidnight)
        let nextDay = provider.localDay(for: midnight)

        #expect(!provider.isSameDay(lateDay, nextDay))
        #expect(provider.nextDay(after: lateDay) == nextDay)
    }
}
