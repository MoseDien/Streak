import Foundation
import SwiftData
import Observation

/// Concrete `ProjectManaging` backed by SwiftData (CLAUDE.md §18.1).
///
/// Marked `@Observable` so it can be injected into the SwiftUI environment;
/// it holds no observable UI state itself. All domain rules live in the
/// injected policies. Notification side-effects are best-effort and never
/// block a data save (CLAUDE.md §28).
@MainActor
@Observable
final class ProjectService: ProjectManaging {
    private let context: ModelContext
    private let transitionPolicy: ProjectStatusTransitionPolicy
    private let activePolicy: ActiveProjectPolicy
    private let notificationService: any NotificationScheduling

    init(
        context: ModelContext,
        notificationService: any NotificationScheduling,
        transitionPolicy: ProjectStatusTransitionPolicy = ProjectStatusTransitionPolicy(),
        activePolicy: ActiveProjectPolicy = ActiveProjectPolicy()
    ) {
        self.context = context
        self.notificationService = notificationService
        self.transitionPolicy = transitionPolicy
        self.activePolicy = activePolicy
    }

    @discardableResult
    func createProject(_ input: NewProjectInput) throws -> LearningProject {
        let title = Self.trimmed(input.title)
        guard !title.isEmpty else { throw ProjectError.emptyTitle }
        let times = try Self.validatedTimes(input.reminderTimes, enabled: input.remindersEnabled)

        let project = LearningProject(
            title: title,
            dailyNote: Self.trimmed(input.dailyNote),
            status: input.status,
            remindersEnabled: input.remindersEnabled
        )
        context.insert(project)
        for timeInput in times {
            context.insert(ReminderEntry(
                id: timeInput.id,
                hour: timeInput.time.hour,
                minute: timeInput.time.minute,
                project: project
            ))
        }
        try context.save()
        // New projects are `notStarted`; no reminder to schedule (CLAUDE.md §21.3).
        return project
    }

    func updateProject(
        id: UUID,
        title: String,
        dailyNote: String,
        reminderTimes: [ReminderTimeInput],
        remindersEnabled: Bool
    ) async throws {
        guard let project = try fetch(id: id) else { throw ProjectError.projectNotFound }
        let trimmedTitle = Self.trimmed(title)
        guard !trimmedTitle.isEmpty else { throw ProjectError.emptyTitle }
        let times = try Self.validatedTimes(reminderTimes, enabled: remindersEnabled)
        let previousReminderIDs = Set((project.reminderEntries ?? []).map(\.id))
        let updatedReminderIDs = Set(times.map(\.id))
        let removedReminderIDs = previousReminderIDs.subtracting(updatedReminderIDs)

        project.title = trimmedTitle
        project.dailyNote = Self.trimmed(dailyNote)
        project.remindersEnabled = remindersEnabled
        project.updatedAt = Date.now
        applyReminderTimes(times, to: project)
        try context.save()

        // Stable identifiers let `add` replace retained reminders in place.
        // Schedule first so a transient add failure does not erase working
        // reminders, then remove only entries no longer present.
        if project.status == .inProgress {
            guard project.remindersEnabled else {
                await notificationService.cancelAllReminders(forProject: id)
                return
            }
            for reminder in ProjectReminder.reminders(for: project) {
                try? await notificationService.scheduleReminder(for: reminder)
            }
            for reminderID in removedReminderIDs {
                await notificationService.cancelReminder(projectID: id, reminderID: reminderID)
            }
        }
    }

    func requestStatusChange(
        projectID: UUID,
        to newStatus: ProjectStatus,
        acknowledgesActiveLimitRecommendation: Bool
    ) async throws -> ProjectStatusChangeResult {
        guard let project = try fetch(id: projectID) else { throw ProjectError.projectNotFound }
        let origin = project.status

        guard transitionPolicy.canTransition(from: origin, to: newStatus) else {
            throw ProjectError.invalidStatusTransition(from: origin, to: newStatus)
        }

        if newStatus == .inProgress && origin != .inProgress && !acknowledgesActiveLimitRecommendation {
            let currentCount = activeProjectCount()
            if case .exceedsRecommendation(let count, let max) = activePolicy.evaluateActivation(activeProjectCount: currentCount) {
                return .requiresActiveLimitConfirmation(currentCount: count, recommendedMaximum: max)
            }
        }

        project.status = newStatus
        project.updatedAt = Date.now
        try context.save()
        await syncNotifications(transitionFrom: origin, to: newStatus, project: project)
        return .performed
    }

    func deleteProject(id: UUID) async throws {
        guard let project = try fetch(id: id) else { throw ProjectError.projectNotFound }
        let wasActive = project.status == .inProgress
        context.delete(project)
        try context.save()
        if wasActive {
            await notificationService.cancelAllReminders(forProject: id)
        }
    }

    func activeProjectCount() -> Int {
        let inProgressRaw = ProjectStatus.inProgress.rawValue
        let descriptor = FetchDescriptor<LearningProject>(
            predicate: #Predicate { $0.statusRawValue == inProgressRaw }
        )
        return (try? context.fetchCount(descriptor)) ?? 0
    }

    /// Schedules on enter to `inProgress`, cancels on leave. Authorization is
    /// requested only as part of an explicit user action (starting a project).
    private func syncNotifications(
        transitionFrom origin: ProjectStatus,
        to destination: ProjectStatus,
        project: LearningProject
    ) async {
        if destination == .inProgress && origin != .inProgress {
            _ = await notificationService.ensureAuthorized()
            if project.remindersEnabled {
                for reminder in ProjectReminder.reminders(for: project) {
                    try? await notificationService.scheduleReminder(for: reminder)
                }
            }
        } else if origin == .inProgress && destination != .inProgress {
            await notificationService.cancelAllReminders(forProject: project.id)
        }
    }

    /// Diffs reminder entries by id: deletes entries absent from `times`,
    /// updates the hour/minute of present ones, inserts new ones.
    private func applyReminderTimes(_ times: [ReminderTimeInput], to project: LearningProject) {
        let existing = project.reminderEntries ?? []
        let inputIDs = Set(times.map(\.id))

        for entry in existing where !inputIDs.contains(entry.id) {
            context.delete(entry)
        }

        let existingByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        for input in times {
            if let entry = existingByID[input.id] {
                entry.hour = input.time.hour
                entry.minute = input.time.minute
            } else {
                context.insert(ReminderEntry(
                    id: input.id,
                    hour: input.time.hour,
                    minute: input.time.minute,
                    project: project
                ))
            }
        }
    }

    private func fetch(id: UUID) throws -> LearningProject? {
        try context.fetch(FetchDescriptor<LearningProject>(
            predicate: #Predicate { $0.id == id }
        )).first
    }

    private static func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Validates ranges, the per-project cap, presence (when enabled), and
    /// uniqueness of reminder times.
    private static func validatedTimes(_ inputs: [ReminderTimeInput], enabled: Bool) throws -> [ReminderTimeInput] {
        if enabled && inputs.isEmpty { throw ProjectError.noReminderTimes }
        guard inputs.count <= ReminderPolicy.maxPerProject else {
            throw ProjectError.tooManyReminders(max: ReminderPolicy.maxPerProject)
        }
        var validated: [ReminderTimeInput] = []
        var seen = Set<ReminderTime>()
        for input in inputs {
            let time = try ReminderTime.validating(hour: input.time.hour, minute: input.time.minute)
            if seen.contains(time) { throw ProjectError.duplicateReminderTime }
            seen.insert(time)
            validated.append(ReminderTimeInput(id: input.id, time: time))
        }
        return validated
    }
}
