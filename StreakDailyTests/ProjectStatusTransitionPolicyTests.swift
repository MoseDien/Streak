import Testing
import Foundation
@testable import StreakDaily

@Suite("Project status transitions (CLAUDE.md §7)")
struct ProjectStatusTransitionPolicyTests {
    private let policy = ProjectStatusTransitionPolicy()

    @Test("notStarted may only become inProgress or failed")
    func notStartedTransitions() {
        #expect(policy.canTransition(from: .notStarted, to: .inProgress))
        #expect(policy.canTransition(from: .notStarted, to: .failed))
        #expect(!policy.canTransition(from: .notStarted, to: .paused))
        #expect(!policy.canTransition(from: .notStarted, to: .completed))
    }

    @Test("inProgress may become paused, failed, or completed")
    func inProgressTransitions() {
        #expect(policy.canTransition(from: .inProgress, to: .paused))
        #expect(policy.canTransition(from: .inProgress, to: .failed))
        #expect(policy.canTransition(from: .inProgress, to: .completed))
        #expect(!policy.canTransition(from: .inProgress, to: .notStarted))
    }

    @Test("paused may become inProgress, failed, or completed")
    func pausedTransitions() {
        #expect(policy.canTransition(from: .paused, to: .inProgress))
        #expect(policy.canTransition(from: .paused, to: .failed))
        #expect(policy.canTransition(from: .paused, to: .completed))
        #expect(!policy.canTransition(from: .paused, to: .notStarted))
    }

    @Test("failed is terminal: no outgoing transitions")
    func failedIsTerminal() {
        for destination in ProjectStatus.allCases where destination != .failed {
            #expect(!policy.canTransition(from: .failed, to: destination))
        }
    }

    @Test("completed is terminal: no outgoing transitions")
    func completedIsTerminal() {
        for destination in ProjectStatus.allCases where destination != .completed {
            #expect(!policy.canTransition(from: .completed, to: destination))
        }
    }

    @Test("re-asserting the same status is an allowed no-op")
    func sameStateIsNoOp() {
        for status in ProjectStatus.allCases {
            #expect(policy.canTransition(from: status, to: status))
        }
    }
}
