import Testing
import Foundation
@testable import StreakDaily

@Suite("Active project policy (CLAUDE.md §8)")
struct ActiveProjectPolicyTests {
    private let policy = ActiveProjectPolicy()

    @Test("activating up to three projects is allowed")
    func allowsUpToThree() {
        #expect(policy.evaluateActivation(activeProjectCount: 0) == .allowed)
        #expect(policy.evaluateActivation(activeProjectCount: 1) == .allowed)
        #expect(policy.evaluateActivation(activeProjectCount: 2) == .allowed)
    }

    @Test("activating a fourth project exceeds the recommendation")
    func exceedsOnFourth() {
        let result = policy.evaluateActivation(activeProjectCount: 3)
        #expect(result == .exceedsRecommendation(currentCount: 3, recommendedMaximum: 3))
    }

    @Test("higher counts keep exceeding the recommendation")
    func keepsExceeding() {
        let result = policy.evaluateActivation(activeProjectCount: 5)
        #expect(result == .exceedsRecommendation(currentCount: 5, recommendedMaximum: 3))
    }

    @Test("the recommended maximum is three")
    func recommendedMaximum() {
        #expect(ActiveProjectPolicy.recommendedMaximum == 3)
    }
}
