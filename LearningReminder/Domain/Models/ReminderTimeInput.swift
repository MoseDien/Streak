import Foundation

/// An editor-proposed reminder time carrying a stable identity. The service
/// diffs persisted `ReminderEntry`s by this `id`, so an unchanged reminder
/// keeps its notification identifier across edits.
struct ReminderTimeInput: Sendable, Equatable, Identifiable {
    let id: UUID
    var time: ReminderTime

    init(id: UUID = UUID(), time: ReminderTime) {
        self.id = id
        self.time = time
    }
}
