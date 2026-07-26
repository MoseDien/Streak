import SwiftUI
import SwiftData

@main
struct LearningReminderApp: App {
    @Environment(\.scenePhase) private var scenePhase

    private let dependencies: AppDependencies

    init() {
        do {
            dependencies = try AppDependencies()
        } catch {
            // SwiftData store initialization is unrecoverable at launch.
            // A user-facing error surface is introduced in a later phase.
            fatalError("Unable to initialize data store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ProjectListView()
                .environment(dependencies.projectService)
                .task { await dependencies.reconciliationService.reconcile() }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    Task { await dependencies.reconciliationService.reconcile() }
                }
        }
        .modelContainer(dependencies.container)
    }
}
