import Foundation
import SwiftData

/// Creates the SwiftData model container (CLAUDE.md §17, §26).
enum ModelContainerFactory {
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            LearningProject.self,
            DailyCheckIn.self,
            ReminderEntry.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
