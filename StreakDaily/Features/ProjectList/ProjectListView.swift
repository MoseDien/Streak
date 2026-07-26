import SwiftUI
import SwiftData

/// The root screen: projects grouped by lifecycle status (CLAUDE.md §21.1).
struct ProjectListView: View {
    @Query(sort: \LearningProject.createdAt, order: .reverse) private var projects: [LearningProject]
    @State private var path: [AppRoute] = []
    @State private var showingCreate = false

    private var sections: [ProjectSection] {
        ProjectSectioning.sections(from: projects)
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if projects.isEmpty {
                    ContentUnavailableView(
                        "No Projects Yet",
                        systemImage: "checkmark.seal",
                        description: Text("Add up to three learning projects to focus on each day.")
                    )
                } else {
                    projectList
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Project", systemImage: "plus") {
                        showingCreate = true
                    }
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .projectDetail(let id):
                    ProjectDetailView(projectID: id)
                }
            }
            .sheet(isPresented: $showingCreate) {
                ProjectEditorView(mode: .create)
            }
        }
    }

    private var projectList: some View {
        List {
            ForEach(sections) { section in
                Section(section.title) {
                    ForEach(section.projects) { project in
                        NavigationLink(value: AppRoute.projectDetail(project.id)) {
                            ProjectRowView(project: project)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

#Preview {
    ProjectListView()
        .modelContainer(try! ModelContainerFactory.makeContainer(inMemory: true))
}
