import SwiftUI
import SwiftData

@main
struct StreakDailyApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var didFinishLaunch = false

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
            ZStack {
                ProjectListView()
                    .environment(dependencies.projectService)
                    .task { await dependencies.reconciliationService.reconcile() }
                    .onChange(of: scenePhase) { _, newPhase in
                        guard newPhase == .active else { return }
                        Task { await dependencies.reconciliationService.reconcile() }
                    }

                if !didFinishLaunch {
                    LaunchView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .task {
                // Cancellation only short-circuits the wait; the launch view
                // is dismissed either way.
                try? await Task.sleep(for: .seconds(1.5))
                withAnimation(.easeInOut(duration: 0.5)) {
                    didFinishLaunch = true
                }
            }
        }
        .modelContainer(dependencies.container)
    }
}
