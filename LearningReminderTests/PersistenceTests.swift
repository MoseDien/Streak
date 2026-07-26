import Testing
import Foundation
import SwiftData
@testable import LearningReminder

@MainActor
@Suite("SwiftData persistence (CLAUDE.md §31.6)")
struct PersistenceTests {
    private static let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeContainer() throws -> ModelContainer {
        try ModelContainerFactory.makeContainer(inMemory: true)
    }

    @Test("saving and fetching a project")
    func saveAndFetchProject() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        context.insert(LearningProject(title: "Learn German"))
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<LearningProject>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.title == "Learn German")
    }

    @Test("check-in is associated with its project")
    func checkInRelationship() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = LearningProject(title: "Chess")
        context.insert(project)
        context.insert(DailyCheckIn(localDay: Self.referenceDate, project: project))
        try context.save()

        let fetchedCheckIns = try context.fetch(FetchDescriptor<DailyCheckIn>())
        #expect(fetchedCheckIns.count == 1)
        #expect(fetchedCheckIns.first?.project?.title == "Chess")
        #expect(project.checkIns?.count == 1)
    }

    @Test("deleting a project cascades to its check-ins")
    func cascadeDelete() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = LearningProject(title: "Swift concurrency")
        context.insert(project)
        context.insert(DailyCheckIn(localDay: Self.referenceDate, project: project))
        try context.save()

        context.delete(project)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<DailyCheckIn>())
        #expect(remaining.isEmpty)
    }

    @Test("deleting a project cascades to its reminder entries")
    func cascadeReminderEntries() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = LearningProject(title: "Swift concurrency")
        context.insert(project)
        context.insert(ReminderEntry(hour: 8, minute: 0, project: project))
        context.insert(ReminderEntry(hour: 20, minute: 0, project: project))
        try context.save()

        context.delete(project)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<ReminderEntry>())
        #expect(remaining.isEmpty)
    }

    @Test("unknown status raw value falls back to the default")
    func enumRawValueFallback() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = LearningProject(title: "Fallback")
        project.statusRawValue = "notARealStatus"
        context.insert(project)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<LearningProject>()).first
        #expect(fetched?.status == .notStarted)
    }

    @Test("finalized status and timestamp persist")
    func finalizedResultPersistence() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = LearningProject(title: "German", status: .inProgress)
        context.insert(project)
        let checkIn = DailyCheckIn(localDay: Self.referenceDate, status: .pending, project: project)
        context.insert(checkIn)

        checkIn.status = .completed
        checkIn.finalizedAt = Self.referenceDate
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<DailyCheckIn>()).first
        #expect(fetched?.status == .completed)
        #expect(fetched?.finalizedAt == Self.referenceDate)
    }
}
