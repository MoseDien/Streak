import Foundation

/// User-facing display metadata for a project status (CLAUDE.md §21.1, §22).
/// Status is never conveyed by color alone — the symbol and label carry meaning.
extension ProjectStatus {
    var displayName: String {
        switch self {
        case .notStarted: "Not Started"
        case .inProgress: "In Progress"
        case .paused: "Paused"
        case .completed: "Completed"
        case .failed: "Abandoned"
        }
    }

    var symbolName: String {
        switch self {
        case .notStarted: "circle"
        case .inProgress: "circle.fill"
        case .paused: "pause.circle"
        case .completed: "checkmark.circle.fill"
        case .failed: "xmark.circle"
        }
    }
}

/// A displayable group of projects sharing one lifecycle status.
struct ProjectSection: Identifiable {
    let status: ProjectStatus
    let projects: [LearningProject]

    var id: ProjectStatus { status }
    var title: String { status.displayName }
}

/// Pure grouping of projects into ordered sections (CLAUDE.md §21.1).
enum ProjectSectioning {
    /// Sections in the recommended display order; empty sections are omitted.
    static func sections(from projects: [LearningProject]) -> [ProjectSection] {
        let order: [ProjectStatus] = [.inProgress, .notStarted, .paused, .completed, .failed]
        return order.compactMap { status in
            let items = projects.filter { $0.status == status }
            return items.isEmpty ? nil : ProjectSection(status: status, projects: items)
        }
    }
}
