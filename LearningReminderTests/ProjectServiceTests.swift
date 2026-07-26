import Testing
import Foundation
import SwiftData
@testable import LearningReminder

@MainActor
@Suite("Project service (CLAUDE.md §7, §8, §18.1, §31.1, §31.2, §31.5)")
struct ProjectServiceTests {
    /// Owns the in-memory container so its context stays valid for the whole
    /// test. The container must outlive every use of its context.
    @MainActor
    private final class ServiceFixture {
        let container: ModelContainer
        let context: ModelContext
        let notifications: MockNotificationService
        let service: ProjectService

        init() throws {
            container = try ModelContainerFactory.makeContainer(inMemory: true)
            context = container.mainContext
            notifications = MockNotificationService()
            service = ProjectService(context: context, notificationService: notifications)
        }
    }

    private func inputs(_ times: ReminderTime...) -> [ReminderTimeInput] {
        times.map { ReminderTimeInput(time: $0) }
    }

    @Test("creating a project persists one default reminder and schedules nothing")
    func createProject() throws {
        let fixture = try ServiceFixture()
        let project = try fixture.service.createProject(NewProjectInput(title: "Learn German"))

        #expect(project.title == "Learn German")
        #expect(project.status == .notStarted)
        #expect(project.reminderEntries?.count == 1)
        #expect(fixture.notifications.scheduled.isEmpty)
    }

    @Test("creating a project with several reminders persists one entry per time")
    func createWithMultipleReminders() throws {
        let fixture = try ServiceFixture()
        let project = try fixture.service.createProject(NewProjectInput(
            title: "German",
            reminderTimes: inputs(ReminderTime(hour: 8), ReminderTime(hour: 12, minute: 30), ReminderTime(hour: 20))
        ))

        #expect(project.reminderEntries?.count == 3)
    }

    @Test("creating a project with a blank title throws")
    func emptyTitleThrows() throws {
        let fixture = try ServiceFixture()
        #expect(throws: ProjectError.emptyTitle) {
            _ = try fixture.service.createProject(NewProjectInput(title: "   "))
        }
    }

    @Test("more than three reminders throws")
    func tooManyReminders() throws {
        let fixture = try ServiceFixture()
        #expect(throws: ProjectError.tooManyReminders(max: 3)) {
            _ = try fixture.service.createProject(NewProjectInput(
                title: "X",
                reminderTimes: inputs(ReminderTime(hour: 1), ReminderTime(hour: 2), ReminderTime(hour: 3), ReminderTime(hour: 4))
            ))
        }
    }

    @Test("enabling reminders with no times throws")
    func noReminderTimes() throws {
        let fixture = try ServiceFixture()
        #expect(throws: ProjectError.noReminderTimes) {
            _ = try fixture.service.createProject(NewProjectInput(title: "X", reminderTimes: [], remindersEnabled: true))
        }
    }

    @Test("duplicate reminder times throw")
    func duplicateReminderTime() throws {
        let fixture = try ServiceFixture()
        #expect(throws: ProjectError.duplicateReminderTime) {
            _ = try fixture.service.createProject(NewProjectInput(
                title: "X",
                reminderTimes: inputs(ReminderTime(hour: 8), ReminderTime(hour: 8))
            ))
        }
    }

    @Test("titles and notes are trimmed before saving")
    func trimming() throws {
        let fixture = try ServiceFixture()
        let project = try fixture.service.createProject(NewProjectInput(title: "  Chess  ", dailyNote: "  ten puzzles  "))
        #expect(project.title == "Chess")
        #expect(project.dailyNote == "ten puzzles")
    }

    @Test("starting a project schedules each reminder and requests authorization")
    func startProject() async throws {
        let fixture = try ServiceFixture()
        let project = try fixture.service.createProject(NewProjectInput(title: "Chess"))

        let result = try await fixture.service.requestStatusChange(
            projectID: project.id, to: .inProgress, acknowledgesActiveLimitRecommendation: false
        )

        #expect(result == .performed)
        #expect(project.status == .inProgress)
        #expect(fixture.notifications.scheduled.count == 1)
        #expect(fixture.notifications.scheduled.first?.projectID == project.id)
        #expect(fixture.notifications.ensureAuthorizedCount == 1)
    }

    @Test("starting a project with multiple reminders schedules one notification each")
    func startWithMultipleReminders() async throws {
        let fixture = try ServiceFixture()
        let project = try fixture.service.createProject(NewProjectInput(
            title: "German",
            reminderTimes: inputs(ReminderTime(hour: 8), ReminderTime(hour: 20))
        ))

        _ = try await fixture.service.requestStatusChange(
            projectID: project.id, to: .inProgress, acknowledgesActiveLimitRecommendation: false
        )

        let scheduled = fixture.notifications.scheduled
        #expect(scheduled.count == 2)
        #expect(scheduled.allSatisfy { $0.projectID == project.id })
        #expect(Set(scheduled.map(\.reminderID)).count == 2)
    }

    @Test("pausing an active project cancels all its reminders")
    func pauseCancelsReminder() async throws {
        let fixture = try ServiceFixture()
        let project = try fixture.service.createProject(NewProjectInput(
            title: "Chess",
            reminderTimes: inputs(ReminderTime(hour: 8), ReminderTime(hour: 20))
        ))
        _ = try await fixture.service.requestStatusChange(
            projectID: project.id, to: .inProgress, acknowledgesActiveLimitRecommendation: false
        )

        _ = try await fixture.service.requestStatusChange(
            projectID: project.id, to: .paused, acknowledgesActiveLimitRecommendation: false
        )

        #expect(fixture.notifications.cancelledAllForProject.contains(project.id))
    }

    @Test("failing an active project cancels all its reminders")
    func failCancelsReminder() async throws {
        let fixture = try ServiceFixture()
        let project = try fixture.service.createProject(NewProjectInput(title: "Chess"))
        _ = try await fixture.service.requestStatusChange(
            projectID: project.id, to: .inProgress, acknowledgesActiveLimitRecommendation: false
        )

        _ = try await fixture.service.requestStatusChange(
            projectID: project.id, to: .failed, acknowledgesActiveLimitRecommendation: false
        )

        #expect(fixture.notifications.cancelledAllForProject.contains(project.id))
    }

    @Test("activating a fourth project requests acknowledgement and schedules nothing for it")
    func fourthActivationRequestsAcknowledgement() async throws {
        let fixture = try ServiceFixture()
        for index in 0 ..< 3 {
            let project = try fixture.service.createProject(NewProjectInput(title: "P\(index)"))
            _ = try await fixture.service.requestStatusChange(
                projectID: project.id, to: .inProgress, acknowledgesActiveLimitRecommendation: false
            )
        }
        let fourth = try fixture.service.createProject(NewProjectInput(title: "P3"))

        let result = try await fixture.service.requestStatusChange(
            projectID: fourth.id, to: .inProgress, acknowledgesActiveLimitRecommendation: false
        )

        #expect(result == .requiresActiveLimitConfirmation(currentCount: 3, recommendedMaximum: 3))
        #expect(fourth.status == .notStarted)
        #expect(fixture.notifications.scheduled.allSatisfy { $0.projectID != fourth.id })
    }

    @Test("acknowledging the recommendation activates the fourth project and schedules its reminder")
    func acknowledgingActivates() async throws {
        let fixture = try ServiceFixture()
        for index in 0 ..< 3 {
            let project = try fixture.service.createProject(NewProjectInput(title: "P\(index)"))
            _ = try await fixture.service.requestStatusChange(
                projectID: project.id, to: .inProgress, acknowledgesActiveLimitRecommendation: false
            )
        }
        let fourth = try fixture.service.createProject(NewProjectInput(title: "P3"))

        let result = try await fixture.service.requestStatusChange(
            projectID: fourth.id, to: .inProgress, acknowledgesActiveLimitRecommendation: true
        )

        #expect(result == .performed)
        #expect(fourth.status == .inProgress)
        #expect(fixture.notifications.scheduled.contains { $0.projectID == fourth.id })
    }

    @Test("a transition from a terminal state throws")
    func terminalStateRejectsTransition() async throws {
        let fixture = try ServiceFixture()
        let project = try fixture.service.createProject(NewProjectInput(title: "X", status: .completed))

        do {
            _ = try await fixture.service.requestStatusChange(
                projectID: project.id, to: .inProgress, acknowledgesActiveLimitRecommendation: false
            )
            Issue.record("Expected an invalidStatusTransition error")
        } catch let error as ProjectError {
            if case .invalidStatusTransition(let from, let to) = error {
                #expect(from == .completed)
                #expect(to == .inProgress)
            } else {
                Issue.record("Unexpected ProjectError case: \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("completing an active project cancels all its reminders")
    func completeProject() async throws {
        let fixture = try ServiceFixture()
        let project = try fixture.service.createProject(NewProjectInput(title: "X"))
        _ = try await fixture.service.requestStatusChange(
            projectID: project.id, to: .inProgress, acknowledgesActiveLimitRecommendation: false
        )

        _ = try await fixture.service.requestStatusChange(
            projectID: project.id, to: .completed, acknowledgesActiveLimitRecommendation: false
        )

        #expect(project.status == .completed)
        #expect(fixture.notifications.cancelledAllForProject.contains(project.id))
    }

    @Test("updating an active project replaces its reminders")
    func updateProject() async throws {
        let fixture = try ServiceFixture()
        let project = try fixture.service.createProject(NewProjectInput(title: "Old"))
        _ = try await fixture.service.requestStatusChange(
            projectID: project.id, to: .inProgress, acknowledgesActiveLimitRecommendation: false
        )
        fixture.notifications.reset()

        try await fixture.service.updateProject(
            id: project.id,
            title: "New",
            dailyNote: "read twenty minutes",
            reminderTimes: inputs(ReminderTime(hour: 9, minute: 30)),
            remindersEnabled: true
        )

        #expect(project.title == "New")
        #expect(project.dailyNote == "read twenty minutes")
        #expect(project.reminderEntries?.count == 1)
        #expect(project.reminderEntries?.first?.hour == 9)
        #expect(fixture.notifications.cancelledAllForProject.isEmpty)
        #expect(fixture.notifications.scheduled.count == 1)
        #expect(fixture.notifications.scheduled.first?.reminderTime.hour == 9)
    }

    @Test("removing one reminder of an active project reschedules only the rest")
    func updateRemovingOneReminder() async throws {
        let fixture = try ServiceFixture()
        let project = try fixture.service.createProject(NewProjectInput(
            title: "X",
            reminderTimes: inputs(ReminderTime(hour: 8), ReminderTime(hour: 20))
        ))
        _ = try await fixture.service.requestStatusChange(
            projectID: project.id, to: .inProgress, acknowledgesActiveLimitRecommendation: false
        )
        fixture.notifications.reset()

        let keepID = try #require(project.reminderEntries?.first?.id)
        let removedID = try #require(project.reminderEntries?.first { $0.id != keepID }?.id)
        try await fixture.service.updateProject(
            id: project.id,
            title: "X",
            dailyNote: "",
            reminderTimes: [ReminderTimeInput(id: keepID, time: ReminderTime(hour: 8))],
            remindersEnabled: true
        )

        #expect(project.reminderEntries?.count == 1)
        #expect(fixture.notifications.cancelledAllForProject.isEmpty)
        #expect(fixture.notifications.cancelledReminders.contains {
            $0.projectID == project.id && $0.reminderID == removedID
        })
        #expect(fixture.notifications.scheduled.count == 1)
    }

    @Test("disabling reminders for an active project cancels without rescheduling")
    func disablingRemindersCancelsOnly() async throws {
        let fixture = try ServiceFixture()
        let project = try fixture.service.createProject(NewProjectInput(title: "X"))
        _ = try await fixture.service.requestStatusChange(
            projectID: project.id, to: .inProgress, acknowledgesActiveLimitRecommendation: false
        )
        fixture.notifications.reset()

        try await fixture.service.updateProject(
            id: project.id,
            title: "X",
            dailyNote: "",
            reminderTimes: inputs(ReminderTime()),
            remindersEnabled: false
        )

        #expect(fixture.notifications.cancelledAllForProject.contains(project.id))
        #expect(fixture.notifications.scheduled.isEmpty)
    }

    @Test("deleting an active project removes it and cancels all its reminders")
    func deleteProject() async throws {
        let fixture = try ServiceFixture()
        let project = try fixture.service.createProject(NewProjectInput(title: "X"))
        _ = try await fixture.service.requestStatusChange(
            projectID: project.id, to: .inProgress, acknowledgesActiveLimitRecommendation: false
        )

        try await fixture.service.deleteProject(id: project.id)

        #expect(try fixture.context.fetch(FetchDescriptor<LearningProject>()).isEmpty)
        #expect(fixture.notifications.cancelledAllForProject.contains(project.id))
    }

    @Test("active project count reflects active projects")
    func activeProjectCount() async throws {
        let fixture = try ServiceFixture()
        #expect(fixture.service.activeProjectCount() == 0)

        let project = try fixture.service.createProject(NewProjectInput(title: "X"))
        _ = try await fixture.service.requestStatusChange(
            projectID: project.id, to: .inProgress, acknowledgesActiveLimitRecommendation: false
        )
        #expect(fixture.service.activeProjectCount() == 1)
    }
}
