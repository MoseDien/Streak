import Testing
import Foundation
@testable import StreakDaily

@Suite("Daily check-in finalization policy (CLAUDE.md §11, §14)")
struct DailyCheckInPolicyTests {
    private let policy = DailyCheckInPolicy()

    private var today: LocalDay { LocalDay(startOfDay: Date(timeIntervalSince1970: 1_700_000_000)) }
    private var tomorrow: LocalDay { LocalDay(startOfDay: Date(timeIntervalSince1970: 1_700_000_000 + 86_400)) }
    private var yesterday: LocalDay { LocalDay(startOfDay: Date(timeIntervalSince1970: 1_700_000_000 - 86_400)) }

    @Test("a pending check-in on today can be finalized")
    func finalizePendingToday() {
        #expect(policy.finalizationError(status: .pending, on: today, relativeTo: today) == nil)
    }

    @Test("a pending check-in on a past day can be finalized")
    func finalizePendingPast() {
        #expect(policy.finalizationError(status: .pending, on: yesterday, relativeTo: today) == nil)
    }

    @Test("a finalized check-in cannot be finalized again")
    func rejectAlreadyFinalized() {
        #expect(policy.finalizationError(status: .completed, on: today, relativeTo: today) == .alreadyFinalized)
        #expect(policy.finalizationError(status: .notCompleted, on: today, relativeTo: today) == .alreadyFinalized)
    }

    @Test("a future day cannot be finalized")
    func rejectFutureDate() {
        #expect(policy.finalizationError(status: .pending, on: tomorrow, relativeTo: today) == .futureDate)
    }

    @Test("finalized status maps from the final result")
    func statusMapping() {
        #expect(policy.status(for: .completed) == .completed)
        #expect(policy.status(for: .notCompleted) == .notCompleted)
    }
}
