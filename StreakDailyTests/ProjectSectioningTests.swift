import Testing
import Foundation
import SwiftData
@testable import StreakDaily

@MainActor
@Suite("Project sectioning (CLAUDE.md §21.1)")
struct ProjectSectioningTests {
    @Test("empty input yields no sections")
    func emptySections() {
        #expect(ProjectSectioning.sections(from: []).isEmpty)
    }

    @Test("projects group by status in the recommended order")
    func groupingOrder() throws {
        let container = try ModelContainerFactory.makeContainer(inMemory: true)
        let context = container.mainContext
        let inProgress = LearningProject(title: "A", status: .inProgress)
        let notStarted = LearningProject(title: "B", status: .notStarted)
        let paused = LearningProject(title: "C", status: .paused)
        context.insert(inProgress)
        context.insert(notStarted)
        context.insert(paused)

        let sections = ProjectSectioning.sections(from: [notStarted, paused, inProgress])

        #expect(sections.map(\.status) == [.inProgress, .notStarted, .paused])
        #expect(sections.first?.projects.first?.title == "A")
    }

    @Test("empty statuses are omitted")
    func emptyStatusesOmitted() throws {
        let container = try ModelContainerFactory.makeContainer(inMemory: true)
        let context = container.mainContext
        let only = LearningProject(title: "X", status: .completed)
        context.insert(only)

        let sections = ProjectSectioning.sections(from: [only])

        #expect(sections.count == 1)
        #expect(sections.first?.status == .completed)
    }
}
