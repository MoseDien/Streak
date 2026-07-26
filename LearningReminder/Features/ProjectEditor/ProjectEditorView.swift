import SwiftUI
import SwiftData

/// Create / edit form for a project (CLAUDE.md §21.3, §21.4, §9). Supports
/// multiple daily reminder times per project (max `ReminderPolicy.maxPerProject`).
struct ProjectEditorView: View {
    enum Mode: Equatable {
        case create
        case edit(UUID)
    }

    let mode: Mode

    @Environment(ProjectService.self) private var service
    @Environment(\.dismiss) private var dismiss
    @Query private var editProjects: [LearningProject]

    @State private var title = ""
    @State private var dailyNote = ""
    @State private var remindersEnabled = true
    @State private var rows: [ReminderRow] = []
    @State private var didLoad = false
    @State private var presentedError: AppError?
    @State private var showError = false

    private struct ReminderRow: Identifiable {
        let id: UUID
        var date: Date
    }

    init(mode: Mode) {
        self.mode = mode
        if case .edit(let id) = mode {
            _editProjects = Query(filter: #Predicate<LearningProject> { $0.id == id })
        }
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var saveButtonTitle: String {
        mode == .create ? "Add" : "Done"
    }

    private var canAddRow: Bool {
        rows.count < ReminderPolicy.maxPerProject
    }

    private var canSave: Bool {
        !trimmedTitle.isEmpty && (!remindersEnabled || !rows.isEmpty)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Project") {
                    TextField("Title", text: $title)
                    TextField("Daily Activity", text: $dailyNote)
                }
                Section("Reminders") {
                    Toggle("Daily Reminders", isOn: $remindersEnabled)
                    if remindersEnabled {
                        ForEach($rows) { $row in
                            DatePicker("Time", selection: $row.date, displayedComponents: .hourAndMinute)
                        }
                        .onDelete { offsets in
                            rows.remove(atOffsets: offsets)
                        }
                        if canAddRow {
                            Button("Add Time", systemImage: "plus") {
                                rows.append(ReminderRow(id: UUID(), date: Self.date(from: ReminderTime())))
                            }
                        }
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saveButtonTitle) { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: loadIfEditing)
            .alert("Error", isPresented: $showError, presenting: presentedError) { _ in
                Button("OK") { presentedError = nil }
            } message: { error in
                Text(error.message)
            }
        }
    }

    private var navigationTitle: String {
        mode == .create ? "New Project" : "Edit Project"
    }

    private func loadIfEditing() {
        guard !didLoad else { return }
        didLoad = true
        if case .edit = mode, let project = editProjects.first {
            title = project.title
            dailyNote = project.dailyNote
            remindersEnabled = project.remindersEnabled
            rows = (project.reminderEntries ?? []).map { entry in
                ReminderRow(id: entry.id, date: Self.date(from: entry.time))
            }
        }
        if rows.isEmpty {
            rows = [ReminderRow(id: UUID(), date: Self.date(from: ReminderTime()))]
        }
    }

    @MainActor
    private func save() {
        let inputs = rows.map { ReminderTimeInput(id: $0.id, time: Self.time(from: $0.date)) }
        Task {
            do {
                switch mode {
                case .create:
                    _ = try service.createProject(NewProjectInput(
                        title: title,
                        dailyNote: dailyNote,
                        reminderTimes: inputs,
                        remindersEnabled: remindersEnabled
                    ))
                case .edit(let id):
                    try await service.updateProject(
                        id: id,
                        title: title,
                        dailyNote: dailyNote,
                        reminderTimes: inputs,
                        remindersEnabled: remindersEnabled
                    )
                }
                dismiss()
            } catch {
                presentedError = AppError(error)
                showError = true
            }
        }
    }

    private static func date(from time: ReminderTime) -> Date {
        Calendar.current.date(from: DateComponents(hour: time.hour, minute: time.minute)) ?? Date.now
    }

    private static func time(from date: Date) -> ReminderTime {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return ReminderTime(hour: components.hour ?? 20, minute: components.minute ?? 0)
    }
}
