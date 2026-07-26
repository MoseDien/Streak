import SwiftUI

/// A single project row in the list (CLAUDE.md §21.1).
struct ProjectRowView: View {
    let project: LearningProject

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(project.title)
                    .font(.body)
                    .bold()
                Spacer(minLength: 8)
                statusBadge
            }
            if !project.dailyNote.isEmpty {
                Text(project.dailyNote)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            if project.remindersEnabled && project.status.receivesDailyReminders {
                Label(reminderText, systemImage: "bell")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var statusBadge: some View {
        Label(project.status.displayName, systemImage: project.status.symbolName)
            .labelStyle(.titleAndIcon)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(project.status.receivesDailyReminders ? AnyShapeStyle(.tint.opacity(0.15)) : AnyShapeStyle(.quaternary), in: .capsule)
            .accessibilityHidden(true)
    }

    private var reminderText: String {
        project.reminderTimes
            .map { time -> String in
                let date = Calendar.current.date(from: DateComponents(hour: time.hour, minute: time.minute)) ?? .now
                return date.formatted(date: .omitted, time: .shortened)
            }
            .joined(separator: ", ")
    }

    private var accessibilityLabel: String {
        var parts = [project.title, project.status.displayName]
        if !project.dailyNote.isEmpty { parts.append(project.dailyNote) }
        if project.remindersEnabled && project.status.receivesDailyReminders { parts.append("Reminder at \(reminderText)") }
        return parts.joined(separator: ", ")
    }
}
