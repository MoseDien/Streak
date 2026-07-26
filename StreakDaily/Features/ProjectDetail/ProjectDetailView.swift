import SwiftUI
import SwiftData

/// Detail screen for one project with explicit status-transition actions
/// (CLAUDE.md §21.2, §22).
struct ProjectDetailView: View {
    let projectID: UUID

    @Environment(ProjectService.self) private var service
    @Environment(\.dismiss) private var dismiss
    @Query private var projects: [LearningProject]

    private let transitionPolicy = ProjectStatusTransitionPolicy()

    @State private var activeLimitInfo: PendingActivation?
    @State private var showActiveLimitDialog = false
    @State private var pendingTerminal: ProjectStatus?
    @State private var showTerminalDialog = false
    @State private var showDeleteDialog = false
    @State private var presentedError: AppError?
    @State private var showError = false
    @State private var showingEdit = false

    init(projectID: UUID) {
        self.projectID = projectID
        let id = projectID
        _projects = Query(filter: #Predicate<LearningProject> { $0.id == id })
    }

    private var project: LearningProject? { projects.first }

    var body: some View {
        Group {
            if let project {
                Form {
                    detailsSection(for: project)
                    actionsSection(for: project)
                }
            } else {
                ContentUnavailableView("Project Not Found", systemImage: "magnifyingglass")
            }
        }
        .navigationTitle(project?.title ?? "Project")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if project != nil {
                    Menu {
                        Button("Edit", systemImage: "pencil") { showingEdit = true }
                        Button("Delete Project", systemImage: "trash", role: .destructive) {
                            showDeleteDialog = true
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            ProjectEditorView(mode: .edit(projectID))
        }
        .confirmationDialog(
            "Start Another Project?",
            isPresented: $showActiveLimitDialog,
            titleVisibility: .visible
        ) {
            Button("Start Anyway") {
                activeLimitInfo = nil
                Task { await performChange(to: .inProgress, acknowledgesLimit: true) }
            }
            Button("Cancel", role: .cancel) { activeLimitInfo = nil }
        } message: {
            if let activeLimitInfo {
                Text("You have \(activeLimitInfo.currentCount) active projects. Focusing on at most \(activeLimitInfo.recommendedMaximum) at a time is recommended.")
            }
        }
        .confirmationDialog(
            terminalDialogTitle,
            isPresented: $showTerminalDialog,
            titleVisibility: .visible
        ) {
            Button("Confirm") {
                let target = pendingTerminal
                pendingTerminal = nil
                if let target { Task { await performChange(to: target) } }
            }
            Button("Cancel", role: .cancel) { pendingTerminal = nil }
        } message: {
            Text(terminalDialogMessage)
        }
        .confirmationDialog(
            "Delete Project?",
            isPresented: $showDeleteDialog,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { deleteProject() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the project and all its daily history. This cannot be undone.")
        }
        .alert("Error", isPresented: $showError, presenting: presentedError) { _ in
            Button("OK") { presentedError = nil }
        } message: { error in
            Text(error.message)
        }
    }

    @ViewBuilder
    private func detailsSection(for project: LearningProject) -> some View {
        Section {
            LabeledContent("Status") {
                Label(project.status.displayName, systemImage: project.status.symbolName)
            }
            if !project.dailyNote.isEmpty {
                LabeledContent("Daily Activity", value: project.dailyNote)
            }
            LabeledContent("Daily Reminder", value: reminderLabel(for: project))
        }
    }

    @ViewBuilder
    private func actionsSection(for project: LearningProject) -> some View {
        let transitions = transitionPolicy.availableTransitions(from: project.status)
        if !transitions.isEmpty {
            Section("Project Actions") {
                ForEach(transitions, id: \.self) { destination in
                    actionButton(for: destination, from: project.status)
                }
            }
        }
        if project.status.isTerminal {
            Section {
                Text(terminalExplanation(for: project.status))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func actionButton(for destination: ProjectStatus, from origin: ProjectStatus) -> some View {
        if destination == .failed {
            Button(actionLabel(for: destination, from: origin), role: .destructive) { requestChange(to: destination) }
        } else {
            Button(actionLabel(for: destination, from: origin)) { requestChange(to: destination) }
        }
    }

    private func actionLabel(for destination: ProjectStatus, from origin: ProjectStatus) -> String {
        switch destination {
        case .inProgress: origin == .paused ? "Resume" : "Start"
        case .paused: "Pause"
        case .completed: "Mark Completed"
        case .failed: "Abandon Project"
        case .notStarted: "Reset to Not Started"
        }
    }

    private func terminalExplanation(for status: ProjectStatus) -> String {
        status == .completed
            ? "This project is completed. Its status cannot be changed."
            : "This project is abandoned. Its status cannot be changed."
    }

    private func reminderLabel(for project: LearningProject) -> String {
        guard project.remindersEnabled else { return "Off" }
        guard project.status.receivesDailyReminders else { return "Off (project not active)" }
        return Self.formattedTimes(project.reminderTimes)
    }

    private static func formattedTimes(_ times: [ReminderTime]) -> String {
        let labels = times.map { time -> String in
            let date = Calendar.current.date(from: DateComponents(hour: time.hour, minute: time.minute)) ?? Date.now
            return date.formatted(date: .omitted, time: .shortened)
        }
        return labels.isEmpty ? "Off" : labels.joined(separator: ", ")
    }

    private var terminalDialogTitle: String {
        pendingTerminal == .completed ? "Mark Project Completed?" : "Abandon Project?"
    }

    private var terminalDialogMessage: String {
        pendingTerminal == .completed
            ? "This marks the project as completed. You can still review its daily history."
            : "This marks the project as abandoned. This cannot be undone."
    }

    @MainActor
    private func requestChange(to status: ProjectStatus) {
        if status.isTerminal {
            pendingTerminal = status
            showTerminalDialog = true
            return
        }
        Task { await performChange(to: status) }
    }

    @MainActor
    private func performChange(to status: ProjectStatus, acknowledgesLimit: Bool = false) async {
        do {
            let result = try await service.requestStatusChange(
                projectID: projectID,
                to: status,
                acknowledgesActiveLimitRecommendation: acknowledgesLimit
            )
            switch result {
            case .performed:
                break
            case .requiresActiveLimitConfirmation(let count, let maximum):
                activeLimitInfo = PendingActivation(currentCount: count, recommendedMaximum: maximum)
                showActiveLimitDialog = true
            }
        } catch {
            present(error)
        }
    }

    @MainActor
    private func deleteProject() {
        Task {
            do {
                try await service.deleteProject(id: projectID)
                dismiss()
            } catch {
                present(error)
            }
        }
    }

    @MainActor
    private func present(_ error: Error) {
        presentedError = AppError(error)
        showError = true
    }

    private struct PendingActivation: Equatable {
        let currentCount: Int
        let recommendedMaximum: Int
    }
}

#Preview {
    NavigationStack {
        ProjectDetailView(projectID: UUID())
    }
    .environment(ProjectService(
        context: try! ModelContainerFactory.makeContainer(inMemory: true).mainContext,
        notificationService: SystemNotificationService()
    ))
}
