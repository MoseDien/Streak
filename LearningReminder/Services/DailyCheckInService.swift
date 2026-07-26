import Foundation
import SwiftData
import Observation

/// Concrete `DailyCheckInManaging` backed by SwiftData (CLAUDE.md §18.2).
///
/// Marked `@Observable` so it can be injected into the SwiftUI environment;
/// it holds no observable UI state itself. Calendar and clock are injected so
/// the rules are deterministic in tests.
@MainActor
@Observable
final class DailyCheckInService: DailyCheckInManaging {
    private let context: ModelContext
    private let calendarProvider: any CalendarProviding
    private let dateProvider: any DateProviding
    private let policy: DailyCheckInPolicy

    init(
        context: ModelContext,
        calendarProvider: any CalendarProviding,
        dateProvider: any DateProviding,
        policy: DailyCheckInPolicy = DailyCheckInPolicy()
    ) {
        self.context = context
        self.calendarProvider = calendarProvider
        self.dateProvider = dateProvider
        self.policy = policy
    }

    func checkIn(for projectID: UUID, on date: Date) throws -> DailyCheckIn {
        guard let project = try fetchProject(projectID) else { throw DailyCheckInError.projectNotFound }
        let day = calendarProvider.localDay(for: date)

        if let existing = existingCheckIn(project: project, day: day) {
            return existing
        }
        guard project.status == .inProgress else { throw DailyCheckInError.invalidProjectState }

        let checkIn = DailyCheckIn(localDay: day.startOfDay, status: .pending, project: project)
        context.insert(checkIn)
        try context.save()
        return checkIn
    }

    func finalize(projectID: UUID, on date: Date, result: FinalDailyResult) throws {
        guard let project = try fetchProject(projectID) else { throw DailyCheckInError.projectNotFound }
        let day = calendarProvider.localDay(for: date)
        let today = calendarProvider.localDay(for: dateProvider.now)

        let checkIn: DailyCheckIn
        if let existing = existingCheckIn(project: project, day: day) {
            checkIn = existing
        } else {
            // Only active projects can receive a brand-new check-in record.
            guard project.status == .inProgress else { throw DailyCheckInError.invalidProjectState }
            checkIn = DailyCheckIn(localDay: day.startOfDay, status: .pending, project: project)
            context.insert(checkIn)
        }

        if let error = policy.finalizationError(status: checkIn.status, on: day, relativeTo: today) {
            throw error
        }

        checkIn.status = policy.status(for: result)
        checkIn.finalizedAt = dateProvider.now
        try context.save()
    }

    /// At most one check-in per project per local day, resolved in-memory from
    /// the relationship (CLAUDE.md §12).
    private func existingCheckIn(project: LearningProject, day: LocalDay) -> DailyCheckIn? {
        (project.checkIns ?? []).first { $0.localDay == day.startOfDay }
    }

    private func fetchProject(_ projectID: UUID) throws -> LearningProject? {
        try context.fetch(FetchDescriptor<LearningProject>(
            predicate: #Predicate { $0.id == projectID }
        )).first
    }
}
