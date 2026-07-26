import Foundation

/// The result of requesting a project status change (CLAUDE.md §8, §18.1).
enum ProjectStatusChangeResult: Equatable, Sendable {
    /// The transition was applied.
    case performed
    /// Activating would exceed the active-project recommendation. The change
    /// was not applied; the caller must get explicit acknowledgement and retry.
    case requiresActiveLimitConfirmation(currentCount: Int, recommendedMaximum: Int)
}

/// Input for creating a new project. New projects default to `notStarted`
/// (CLAUDE.md §21.3).
struct NewProjectInput: Sendable, Equatable {
    var title: String
    var dailyNote: String
    var reminderTimes: [ReminderTimeInput]
    var remindersEnabled: Bool
    var status: ProjectStatus

    init(
        title: String,
        dailyNote: String = "",
        reminderTimes: [ReminderTimeInput] = [ReminderTimeInput(time: ReminderTime())],
        remindersEnabled: Bool = true,
        status: ProjectStatus = .notStarted
    ) {
        self.title = title
        self.dailyNote = dailyNote
        self.reminderTimes = reminderTimes
        self.remindersEnabled = remindersEnabled
        self.status = status
    }
}

/// Centralizes all project mutations and status-transition authorization
/// (CLAUDE.md §7, §17, §18.1). Views must not mutate projects directly.
@MainActor
protocol ProjectManaging {
    @discardableResult
    func createProject(_ input: NewProjectInput) throws -> LearningProject

    func updateProject(
        id: UUID,
        title: String,
        dailyNote: String,
        reminderTimes: [ReminderTimeInput],
        remindersEnabled: Bool
    ) async throws

    func requestStatusChange(
        projectID: UUID,
        to newStatus: ProjectStatus,
        acknowledgesActiveLimitRecommendation: Bool
    ) async throws -> ProjectStatusChangeResult

    func deleteProject(id: UUID) async throws

    func activeProjectCount() -> Int
}
