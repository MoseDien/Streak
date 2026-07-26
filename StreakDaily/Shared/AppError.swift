import Foundation

/// A user-facing error wrapper. Domain errors are mapped to plain messages;
/// technical details are never surfaced to the user (CLAUDE.md §28).
struct AppError: Identifiable {
    let id = UUID()
    let message: String

    init(_ error: Error) {
        switch error {
        case ProjectError.projectNotFound:
            message = "This project could not be found."
        case ProjectError.emptyTitle:
            message = "A title is required."
        case ProjectError.tooManyReminders(let max):
            message = "A project can have at most \(max) reminders."
        case ProjectError.noReminderTimes:
            message = "Add at least one reminder time, or turn reminders off."
        case ProjectError.duplicateReminderTime:
            message = "Each reminder time must be different."
        case ReminderTime.ValidationError.invalidHour, ReminderTime.ValidationError.invalidMinute:
            message = "The reminder time is invalid."
        default:
            message = "Something went wrong. Please try again."
        }
    }
}
