import Testing
import Foundation
@testable import LearningReminder

@Suite("Notification identifiers (CLAUDE.md §15.3, §15.4)")
struct NotificationIdentifiersTests {
    @Test("reminder identifier is deterministic and round-trips both ids")
    func deterministicIdentifier() {
        let projectID = UUID()
        let reminderID = UUID()
        let identifier = NotificationIdentifiers.reminderIdentifier(for: projectID, reminderID: reminderID)
        #expect(identifier == "project.daily-reminder.\(projectID.uuidString).\(reminderID.uuidString)")

        let parsed = NotificationIdentifiers.parseReminderIdentifier(identifier)
        #expect(parsed?.projectID == projectID)
        #expect(parsed?.reminderID == reminderID)
        #expect(NotificationIdentifiers.projectID(from: identifier) == projectID)
    }

    @Test("non-project identifiers do not parse")
    func rejectsForeignIdentifiers() {
        #expect(NotificationIdentifiers.parseReminderIdentifier("something.else") == nil)
        #expect(NotificationIdentifiers.projectID(from: "") == nil)
    }
}
