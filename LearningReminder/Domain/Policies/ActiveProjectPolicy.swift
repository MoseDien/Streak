import Foundation

/// The recommendation result of activating one more project (CLAUDE.md §8).
enum ActivationRecommendation: Equatable, Sendable {
    /// The activation is within the recommended number of active projects.
    case allowed
    /// Activating would exceed the recommendation. The count given is the
    /// number of currently active projects, before the new activation.
    case exceedsRecommendation(currentCount: Int, recommendedMaximum: Int)
}

/// Decides whether activating another `inProgress` project stays within the
/// recommended focus limit (CLAUDE.md §8).
///
/// This is a soft recommendation, not a hard constraint: the UI asks the user
/// for an explicit decision when the recommendation is exceeded, and never
/// automatically pauses another project.
struct ActiveProjectPolicy: Sendable {
    static let recommendedMaximum = 3

    /// Evaluates activating one additional project given the number of
    /// currently active projects.
    func evaluateActivation(activeProjectCount: Int) -> ActivationRecommendation {
        precondition(activeProjectCount >= 0, "Active project count must not be negative.")
        let resultingCount = activeProjectCount + 1
        if resultingCount > Self.recommendedMaximum {
            return .exceedsRecommendation(
                currentCount: activeProjectCount,
                recommendedMaximum: Self.recommendedMaximum
            )
        }
        return .allowed
    }
}
