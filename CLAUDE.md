# CLAUDE.md

## 1. Project Overview

This repository contains an iOS application built with Swift and SwiftUI.

The app helps users maintain a small number of active learning projects through:

- Daily scheduled reminders
- Daily completion check-ins
- Immutable daily results
- Project status tracking
- Lightweight progress descriptions
- Local-only SwiftData persistence

The product is intended to encourage focus and consistency rather than complex task management.

The app should generally recommend that users keep no more than three projects in the `inProgress` state at the same time.

---

## 2. Agent Role

You are a Senior iOS Engineer specializing in:

- Swift
- SwiftUI
- SwiftData
- UserNotifications
- Modern Swift concurrency
- Testable application architecture
- Apple Human Interface Guidelines
- App Store review requirements

Always prefer simple, native, maintainable solutions.

Do not introduce third-party frameworks without explicit approval.

Before implementing a feature:

1. Understand the product rule.
2. Identify affected models and services.
3. Consider persistence and migration implications.
4. Consider notification scheduling implications.
5. Add or update unit tests.
6. Build the project and resolve all warnings and errors.

Do not silently change product behavior to make implementation easier.

---

## 3. External Swift Development Guidelines

Follow the Swift and SwiftUI conventions from:

https://github.com/twostraws/SwiftAgents/blob/main/AGENTS.md

The rules in this `CLAUDE.md` take priority when they define app-specific product behavior.

Important inherited rules include:

- Use modern Swift concurrency.
- Prefer `async`/`await` over callback-based APIs.
- Use SwiftUI rather than UIKit unless UIKit is explicitly required.
- Prefer `@Observable` over `ObservableObject`.
- Avoid `ObservableObject`, `@Published`, `@StateObject`, `@ObservedObject`, and `@EnvironmentObject` in new code.
- Treat strict concurrency checking as enabled.
- Avoid force unwraps and force `try`.
- Use modern Foundation APIs and `FormatStyle`.
- Use `NavigationStack`.
- Use `navigationDestination(for:)`.
- Use `Button` rather than `onTapGesture()` for normal interactions.
- Use `foregroundStyle()` rather than `foregroundColor()`.
- Use `clipShape(.rect(cornerRadius:))` rather than `cornerRadius()`.
- Use `Task.sleep(for:)` rather than `Task.sleep(nanoseconds:)`.
- Avoid unnecessary `GeometryReader`.
- Avoid `AnyView`.
- Keep application logic outside SwiftUI view bodies.
- Put separate types in separate Swift files.
- Write unit tests for core business logic.

---

## 4. Platform and Technology Requirements

Use:

- iOS 26.0 or later
- Swift 6.2 or later
- SwiftUI
- SwiftData
- Observation framework
- UserNotifications
- XCTest or Swift Testing
- Modern Swift concurrency

Prefer Apple frameworks only.

Do not add:

- Networking
- User accounts
- Cloud synchronization
- Analytics
- Third-party dependencies

unless explicitly requested.

The initial version is local-only.

---

## 5. Core Product Concepts

The app has two separate concepts:

### 5.1 Learning Project

A long-lived item that the user wants to work on repeatedly.

Examples:

- Learn German
- Study Swift concurrency
- Practice chess tactics

A project has a lifecycle status.

### 5.2 Daily Check-In

A date-specific result for one project.

A daily check-in answers:

> Did the user complete this project's learning activity on this local calendar day?

Daily check-ins must not be confused with project lifecycle status.

For example:

- A project may remain `inProgress`.
- Today's daily check-in may be `notCompleted`.
- Tomorrow the same project can receive another daily check-in.

---

## 6. Project Status

Every learning project has exactly one lifecycle status:

```swift
enum ProjectStatus: String, Codable, CaseIterable {
    case notStarted
    case inProgress
    case paused
    case failed
    case completed
}
```

User-facing meanings:

- `notStarted`: The project has been created but active work has not begun.
- `inProgress`: The project is currently active and receives daily reminders.
- `paused`: The project is temporarily inactive and receives no daily reminders.
- `failed`: The user has abandoned the project or considers the overall project unsuccessful.
- `completed`: The overall learning project has been completed.

Do not use the project status to represent whether one particular day was completed.

---

## 7. Allowed Project Status Transitions

Centralize status transition validation.

Do not allow arbitrary status assignment from views.

Recommended transitions:

```text
notStarted → inProgress
notStarted → failed

inProgress → paused
inProgress → failed
inProgress → completed

paused → inProgress
paused → failed
paused → completed
```

Terminal states:

- `failed`
- `completed`

Terminal project states should not normally return to an active state.

If status restoration is introduced later, it must be an explicit product feature rather than an accidental unrestricted edit.

Whenever a project leaves `inProgress`:

- Remove its pending daily notifications.
- Do not create additional daily check-ins automatically.

Whenever a project enters `inProgress`:

- Validate the active-project recommendation.
- Schedule its next appropriate notification.

---

## 8. Active Project Limit

The product recommends no more than three simultaneous `inProgress` projects.

This is initially a soft limit rather than a hard database constraint.

When the user attempts to activate a fourth project:

1. Show a clear warning.
2. Explain that focusing on at most three active projects is recommended.
3. Allow cancellation.
4. Do not activate the project without an explicit user decision.

Do not automatically pause another project.

All active-project counting logic must live in a testable domain service, not inside a SwiftUI view.

Suggested API:

```swift
struct ActiveProjectPolicy {
    static let recommendedMaximum = 3

    func evaluateActivation(
        activeProjectCount: Int
    ) -> ActivationRecommendation
}
```

Possible result:

```swift
enum ActivationRecommendation: Equatable {
    case allowed
    case exceedsRecommendation(currentCount: Int, recommendedMaximum: Int)
}
```

---

## 9. Project Description

Every active project may contain one short, single-line text description.

Examples:

- Complete one Swift concurrency lesson
- Read German for twenty minutes
- Solve ten chess puzzles

Store this separately from the project title.

Recommended model fields:

- `title`
- `dailyNote`

Requirements:

- `title` is required.
- `dailyNote` is optional or defaults to an empty string.
- The UI should use a single-line text field.
- Trim leading and trailing whitespace before saving.
- Do not store whitespace-only values.
- Apply a reasonable display limit.
- Do not silently truncate persisted text.

A suggested initial limit is 120 characters, but keep validation centralized so it can be changed later.

---

## 10. Daily Check-In Status

Use a dedicated enum for the daily result:

```swift
enum DailyCheckInStatus: String, Codable, CaseIterable {
    case pending
    case completed
    case notCompleted
}
```

Meaning:

- `pending`: No final answer has been submitted for that date.
- `completed`: The user confirmed the activity was completed.
- `notCompleted`: The user confirmed the activity was not completed.

Only `completed` and `notCompleted` are final daily results.

---

## 11. Immutable Daily Result Rule

This is a critical product invariant.

Once a daily check-in changes from `pending` to either:

- `completed`
- `notCompleted`

the result must never be editable through normal application behavior.

This rule must be enforced in the domain layer, not only by disabling UI controls.

Views must not directly mutate the daily status.

Use a dedicated operation such as:

```swift
func finalizeCheckIn(
    _ checkIn: DailyCheckIn,
    as result: FinalDailyResult
) throws
```

Recommended final-result enum:

```swift
enum FinalDailyResult: Sendable {
    case completed
    case notCompleted
}
```

Possible errors:

```swift
enum DailyCheckInError: Error, Equatable {
    case alreadyFinalized
    case futureDate
    case invalidProjectState
}
```

The finalization operation must:

1. Verify the check-in is still `pending`.
2. Verify the check-in represents an allowed date.
3. Set the final status.
4. Set `finalizedAt`.
5. Save the SwiftData context.
6. Update related notifications if necessary.
7. Refuse any later attempt to modify the result.

Never provide a hidden editing path that bypasses this rule.

Deletion of a finalized result should also be prohibited in normal UI.

---

## 12. Date and Calendar Semantics

Daily records are based on the user's local calendar day.

Do not identify a daily record by comparing raw `Date` timestamps alone.

Use:

- `Calendar.autoupdatingCurrent`
- A normalized local start-of-day value
- Explicit date utility functions

Recommended utility:

```swift
struct LocalDay: Hashable, Sendable {
    let startOfDay: Date
}
```

or a centralized date service:

```swift
protocol CalendarProviding: Sendable {
    func startOfDay(for date: Date) -> Date
    func isDateInToday(_ date: Date) -> Bool
    func nextDay(after date: Date) -> Date
}
```

Inject calendar behavior into testable business logic.

Important cases to test:

- Daylight-saving time transitions
- Time-zone changes
- App opened shortly before midnight
- App opened shortly after midnight
- Device clock changes
- Duplicate check-in creation attempts

There must be at most one daily check-in per project per local calendar day.

Because SwiftData uniqueness behavior can complicate future CloudKit support, enforce this invariant through repository or service logic rather than depending exclusively on `@Attribute(.unique)`.

---

## 13. Day-by-Day Continuation

The app must not pre-create months or years of daily records.

Daily progress should continue one day at a time.

Use these rules:

1. Daily check-in records are created lazily.
2. At most one record exists for a project and local day.
3. Opening the app reconciles missing current-day records.
4. Responding to a notification may create today's record if it does not yet exist.
5. Future daily check-in rows are not pre-generated.
6. Past unanswered days are not silently marked completed.
7. A missed previous day may be handled according to the explicit missed-day policy.

Notification delivery and daily record creation are separate concerns.

A repeating calendar notification may be used to ensure reminders continue even if the app is not launched every day. This does not mean the app pre-generates a long series of daily SwiftData records.

---

## 14. Missed-Day Policy

For the initial version:

- Do not automatically finalize a missed day as `notCompleted`.
- Do not automatically finalize a missed day as `completed`.
- Keep unanswered historical records as `pending` only if a record was actually created.
- Do not create a large backlog of historical records when the app has not run.

When the user views an unresolved historical check-in, the app may allow the user to finalize it as:

- completed
- not completed

Once finalized, it becomes immutable.

The app must not allow a result for a future local calendar date.

If product requirements later decide that midnight automatically means failure, implement that as a separate, explicitly tested policy.

Do not assume this behavior.

---

## 15. Local Notification Requirements

Use `UserNotifications`.

Notifications are local notifications only.

Each `inProgress` project can have a daily reminder time.

A project that is not `inProgress` must not have an active daily reminder.

### 15.1 Permission

Request notification authorization only in response to an understandable user action or onboarding explanation.

Do not request authorization immediately without context.

Handle these states:

- notDetermined
- denied
- authorized
- provisional
- ephemeral, if applicable

When denied:

- Keep the project usable.
- Explain that reminders are disabled.
- Provide a path to system settings.
- Do not repeatedly request authorization.

### 15.2 Notification Content

A notification should clearly identify the project.

Suggested content:

- Title: project title
- Body: project daily note or a concise default reminder
- Category identifier: daily project check-in
- User info: stable project identifier

Never use a SwiftData object reference in notification payloads.

Use stable value identifiers such as UUID strings.

### 15.3 Notification Actions

Configure a notification category with actions such as:

- Completed
- Not Completed
- Open App

Destructive language should not be used for a normal missed learning activity.

Notification action identifiers must be centralized constants.

When the user selects `Completed` or `Not Completed`:

1. Resolve the project using its stable identifier.
2. Resolve the correct local day.
3. Find or create the pending daily check-in.
4. Attempt finalization through the same domain service used by the UI.
5. Preserve the immutable-result invariant.
6. Handle duplicate action delivery safely.
7. Schedule or preserve the next reminder as appropriate.

Notification action processing must be idempotent.

Repeated delivery of the same action must not corrupt or overwrite data.

### 15.4 Scheduling Strategy

Use a repeating `UNCalendarNotificationTrigger` for the project's selected daily time unless product requirements explicitly change.

The repeating notification ensures reminders continue even if the app is not launched.

However:

- Do not pre-create future daily records.
- Daily records remain day-specific and lazy.
- Pausing, failing, or completing a project cancels its notification.
- Changing the reminder time replaces the existing notification.
- Notification identifiers must be deterministic per project.

Suggested identifier:

```text
project.daily-reminder.<projectUUID>
```

Avoid scheduling one notification for every future date.

### 15.5 Notification Reconciliation

Create a notification coordinator that can reconcile persisted project state with pending notification requests.

Run reconciliation when appropriate, including:

- App launch
- App becomes active
- Notification permission changes
- Project becomes active
- Project is paused
- Project fails
- Project completes
- Reminder time changes
- Project is deleted

Reconciliation should:

1. Fetch active projects.
2. Fetch pending notification requests.
3. Add missing valid notifications.
4. Replace outdated notifications.
5. Remove orphaned notifications.
6. Remove notifications for inactive or deleted projects.

---

## 16. SwiftData Models

Keep persistence models simple.

Suggested model structure follows.

### 16.1 LearningProject

```swift
@Model
final class LearningProject {
    var id: UUID = UUID()
    var title: String = ""
    var dailyNote: String = ""
    var statusRawValue: String = ProjectStatus.notStarted.rawValue
    var reminderHour: Int = 20
    var reminderMinute: Int = 0
    var remindersEnabled: Bool = true
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    @Relationship(deleteRule: .cascade, inverse: \DailyCheckIn.project)
    var checkIns: [DailyCheckIn]? = []

    init(
        id: UUID = UUID(),
        title: String,
        dailyNote: String = "",
        status: ProjectStatus = .notStarted,
        reminderHour: Int = 20,
        reminderMinute: Int = 0,
        remindersEnabled: Bool = true,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.dailyNote = dailyNote
        self.statusRawValue = status.rawValue
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.remindersEnabled = remindersEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
```

Provide a safe computed property for the enum:

```swift
extension LearningProject {
    var status: ProjectStatus {
        get {
            ProjectStatus(rawValue: statusRawValue) ?? .notStarted
        }
        set {
            statusRawValue = newValue.rawValue
        }
    }
}
```

Do not let SwiftUI views directly bypass transition validation by assigning this property.

### 16.2 DailyCheckIn

```swift
@Model
final class DailyCheckIn {
    var id: UUID = UUID()
    var localDay: Date = Date.now
    var statusRawValue: String = DailyCheckInStatus.pending.rawValue
    var createdAt: Date = Date.now
    var finalizedAt: Date?

    var project: LearningProject?

    init(
        id: UUID = UUID(),
        localDay: Date,
        status: DailyCheckInStatus = .pending,
        createdAt: Date = .now,
        finalizedAt: Date? = nil,
        project: LearningProject
    ) {
        self.id = id
        self.localDay = localDay
        self.statusRawValue = status.rawValue
        self.createdAt = createdAt
        self.finalizedAt = finalizedAt
        self.project = project
    }
}
```

Store `localDay` as a normalized local start-of-day date.

Do not store mutable UI presentation state in SwiftData models.

---

## 17. Model Safety

All SwiftData writes should happen through clearly defined services or repositories.

Views may use `@Query` for simple display queries, but business mutations must be centralized.

Do not place logic such as these directly inside a view:

- Finalizing a check-in
- Changing project status
- Enforcing the three-project recommendation
- Scheduling notifications
- Preventing duplicate daily records
- Normalizing dates
- Validating reminder times

Use one `ModelContext` per intended actor context.

UI-facing SwiftData operations should normally execute on the main actor.

Do not pass live SwiftData model instances into detached tasks.

Use stable identifiers when crossing actor or notification boundaries.

---

## 18. Suggested Services

### 18.1 ProjectService

Responsibilities:

- Create a project
- Update title and daily note
- Validate status transitions
- Count active projects
- Apply active-project recommendation policy
- Pause a project
- Complete a project
- Fail a project
- Delete a project
- Coordinate notification updates

Suggested interface:

```swift
@MainActor
protocol ProjectManaging {
    func createProject(_ input: NewProjectInput) throws -> LearningProject
    func updateProject(
        id: UUID,
        title: String,
        dailyNote: String,
        reminderTime: ReminderTime
    ) throws
    func requestStatusChange(
        projectID: UUID,
        to newStatus: ProjectStatus
    ) async throws -> ProjectStatusChangeResult
    func deleteProject(id: UUID) async throws
}
```

### 18.2 DailyCheckInService

Responsibilities:

- Resolve today's check-in
- Prevent duplicate daily records
- Finalize pending results
- Reject future dates
- Reject changes to finalized results
- Support notification actions safely

Suggested interface:

```swift
@MainActor
protocol DailyCheckInManaging {
    func checkIn(
        for projectID: UUID,
        on date: Date
    ) throws -> DailyCheckIn

    func finalize(
        projectID: UUID,
        on date: Date,
        result: FinalDailyResult
    ) throws
}
```

### 18.3 NotificationService

Responsibilities:

- Request authorization
- Read authorization state
- Register notification categories
- Schedule project reminders
- Cancel project reminders
- Reconcile all pending reminders
- Handle notification actions

Create a protocol so notification behavior can be mocked in tests.

```swift
protocol NotificationScheduling: Sendable {
    func authorizationStatus() async -> NotificationAuthorizationState
    func requestAuthorization() async throws -> Bool
    func scheduleDailyReminder(for project: ProjectReminder) async throws
    func cancelDailyReminder(projectID: UUID) async
    func reconcile(reminders: [ProjectReminder]) async throws
}
```

### 18.4 CalendarService

Responsibilities:

- Normalize local dates
- Resolve today
- Determine tomorrow
- Compare local calendar days
- Support deterministic tests

### 18.5 AppReconciliationService

Responsibilities:

- Ensure current active projects have valid reminders
- Remove stale notifications
- Repair missing current-day state when appropriate
- Keep launch-time maintenance centralized

---

## 19. Observation and State Management

Use the Observation framework.

Shared UI state should use `@Observable`.

Unless the project uses Main Actor as the default actor isolation, mark UI-facing observable classes with `@MainActor`.

Example:

```swift
@MainActor
@Observable
final class ProjectListViewModel {
    private(set) var sections: [ProjectSection] = []
    private(set) var presentedError: AppError?
    var searchText = ""

    private let projectService: any ProjectManaging

    init(projectService: any ProjectManaging) {
        self.projectService = projectService
    }
}
```

Ownership and passing:

- Use `@State` when a view owns an observable object.
- Use `@Bindable` for editable observable state.
- Use `@Environment` for app-level dependencies where appropriate.
- Do not introduce a global singleton service locator.
- Prefer explicit dependency injection.

SwiftData models themselves should not be used as general-purpose view models.

---

## 20. App Navigation

Use `NavigationStack`.

Use typed navigation destinations.

Suggested routes:

```swift
enum AppRoute: Hashable {
    case projectDetail(UUID)
    case createProject
    case editProject(UUID)
    case projectHistory(UUID)
    case notificationSettings
}
```

Use:

```swift
.navigationDestination(for: AppRoute.self)
```

Do not use `NavigationView`.

Do not use string-based routing.

---

## 21. Main Screens

### 21.1 Project List

Display all projects grouped by project lifecycle status.

Recommended order:

1. In Progress
2. Not Started
3. Paused
4. Completed
5. Failed

Empty sections may be hidden.

Each row should display:

- Project title
- Daily note when present
- Project status
- Today's check-in state when relevant
- Reminder state or reminder time when useful

The screen should make active projects visually prominent without relying only on color.

### 21.2 Project Detail

Display:

- Title
- Daily note
- Project status
- Reminder time
- Today's daily check-in
- Historical check-ins
- Allowed project actions

When today's result is pending:

- Show `Completed`
- Show `Not Completed`

When today's result is final:

- Show the final state
- Show when it was finalized
- Do not show editing controls
- Clearly explain that daily answers cannot be changed

### 21.3 Create Project

Collect:

- Title
- Optional daily note
- Initial reminder time
- Whether reminders are enabled
- Initial status

Prefer creating new projects as `notStarted`.

The user can explicitly start the project after creation.

### 21.4 Edit Project

Allow editing:

- Title
- Daily note
- Reminder time
- Reminder enabled state

Do not allow editing finalized daily results.

Project lifecycle status changes should use explicit actions rather than a generic unrestricted picker.

### 21.5 History

Display date-specific check-ins.

Possible sections:

- Completed
- Not Completed
- Pending

Sort newest first.

Use modern date formatting.

Do not use `DateFormatter`.

---

## 22. UI and Accessibility

Follow Apple Human Interface Guidelines.

Requirements:

- Support Dynamic Type.
- Do not force fixed font sizes.
- Provide VoiceOver labels.
- Provide meaningful accessibility values for statuses.
- Do not represent status using color alone.
- Ensure buttons have adequate hit targets.
- Use semantic system colors.
- Support light and dark appearances.
- Use localized user-facing strings.
- Avoid excessive confirmation dialogs.
- Require confirmation for terminal project transitions.
- Clearly explain irreversible daily check-in submission before finalization.

For irreversible daily submission, use a confirmation flow such as:

> Mark today as completed? This answer cannot be changed.

and:

> Mark today as not completed? This answer cannot be changed.

The confirmation is required because the action is irreversible.

Notification actions may finalize directly because the action label itself is explicit. Ensure their labels are unambiguous.

---

## 23. Swift Style Rules

Use clear, descriptive names.

Prefer:

```swift
func finalizeTodayAsCompleted()
```

over:

```swift
func doIt()
```

Additional rules:

- Avoid abbreviations unless universally understood.
- Prefer structs for immutable value types.
- Prefer enums for finite states.
- Prefer protocols at dependency boundaries.
- Avoid speculative generic abstractions.
- Avoid one large manager that owns unrelated behavior.
- Keep methods focused.
- Do not use force unwraps.
- Do not use force `try`.
- Do not use `DispatchQueue.main.async`.
- Prefer structured concurrency.
- Make `Sendable` conformance explicit where appropriate.
- Do not suppress concurrency warnings without documenting why.
- Handle cancellation in asynchronous tasks.
- Do not swallow errors.

Use modern string APIs.

For user-entered search text, use:

```swift
localizedStandardContains()
```

Do not use `contains()` for user-facing localized search behavior.

Use modern URL APIs:

```swift
URL.documentsDirectory
url.appending(path: "filename")
```

Use modern formatting:

```swift
date.formatted(date: .abbreviated, time: .shortened)
```

Do not introduce `DateFormatter`, `NumberFormatter`, or other legacy formatter subclasses.

---

## 24. SwiftUI Style Rules

Always:

- Use `foregroundStyle()`.
- Use `clipShape(.rect(cornerRadius:))`.
- Use `NavigationStack`.
- Use `navigationDestination(for:)`.
- Use `Button` for actions.
- Use the modern `Tab` API.
- Use modern `onChange` overloads.
- Extract substantial UI sections into separate `View` types.

Avoid:

- `foregroundColor()`
- `cornerRadius()`
- `NavigationView`
- `tabItem()`
- One-parameter `onChange`
- `onTapGesture()` for ordinary buttons
- `UIScreen.main.bounds`
- `AnyView`
- Unnecessary `GeometryReader`
- Hard-coded font sizes
- Large view bodies containing business logic
- Computed properties that return complex views

When a button uses a system image, include a text label:

```swift
Button("Add Project", systemImage: "plus") {
    // Action
}
```

Use `bold()` rather than `fontWeight(.bold)` unless a specific non-bold weight is required.

---

## 25. Project Structure

Organize files primarily by feature.

Suggested structure:

```text
LearningReminder/
├── App/
│   ├── LearningReminderApp.swift
│   ├── AppDependencies.swift
│   ├── AppRoute.swift
│   └── AppReconciliationService.swift
│
├── Features/
│   ├── ProjectList/
│   │   ├── ProjectListView.swift
│   │   ├── ProjectListViewModel.swift
│   │   ├── ProjectSection.swift
│   │   └── ProjectRowView.swift
│   │
│   ├── ProjectDetail/
│   │   ├── ProjectDetailView.swift
│   │   ├── ProjectDetailViewModel.swift
│   │   ├── TodayCheckInView.swift
│   │   └── ProjectStatusActionsView.swift
│   │
│   ├── ProjectEditor/
│   │   ├── ProjectEditorView.swift
│   │   ├── ProjectEditorViewModel.swift
│   │   └── ProjectEditorState.swift
│   │
│   ├── ProjectHistory/
│   │   ├── ProjectHistoryView.swift
│   │   └── CheckInRowView.swift
│   │
│   └── NotificationSettings/
│       └── NotificationSettingsView.swift
│
├── Domain/
│   ├── Models/
│   │   ├── ProjectStatus.swift
│   │   ├── DailyCheckInStatus.swift
│   │   ├── FinalDailyResult.swift
│   │   ├── ReminderTime.swift
│   │   └── LocalDay.swift
│   │
│   ├── Policies/
│   │   ├── ActiveProjectPolicy.swift
│   │   ├── ProjectStatusTransitionPolicy.swift
│   │   └── DailyCheckInPolicy.swift
│   │
│   └── Errors/
│       ├── ProjectError.swift
│       └── DailyCheckInError.swift
│
├── Persistence/
│   ├── Models/
│   │   ├── LearningProject.swift
│   │   └── DailyCheckIn.swift
│   │
│   ├── ProjectRepository.swift
│   ├── DailyCheckInRepository.swift
│   └── ModelContainerFactory.swift
│
├── Services/
│   ├── ProjectService.swift
│   ├── DailyCheckInService.swift
│   ├── CalendarService.swift
│   └── Notifications/
│       ├── NotificationService.swift
│       ├── NotificationDelegate.swift
│       ├── NotificationCategory.swift
│       ├── NotificationAction.swift
│       └── ProjectReminder.swift
│
├── Shared/
│   ├── Components/
│   ├── Extensions/
│   ├── Localization/
│   └── Utilities/
│
└── Tests/
    ├── DomainTests/
    ├── PersistenceTests/
    ├── ServiceTests/
    └── FeatureTests/
```

Do not place many unrelated types in one Swift file.

Do not create folders or abstractions until they are used.

---

## 26. Dependency Injection

Create dependencies at the app composition root.

Example responsibilities for `AppDependencies`:

- Model container
- Project service
- Daily check-in service
- Notification service
- Calendar service
- Reconciliation service

Avoid global mutable state.

Avoid direct calls to:

```swift
UNUserNotificationCenter.current()
```

throughout feature code.

Wrap system APIs behind an injected service.

Production implementations may use system singletons internally, but features should depend on protocols.

---

## 27. Notification Delegate Integration

The application must install a notification center delegate early enough to handle notification responses.

Notification delegate responsibilities:

- Handle foreground notification presentation.
- Handle completed/not-completed actions.
- Extract stable project IDs.
- Pass action information to a domain coordinator.
- Avoid performing substantial persistence logic directly in delegate methods.

Bridge delegate callbacks to async code safely.

Do not use unstructured concurrency without considering task lifetime.

Notification-response processing must be:

- Idempotent
- Recoverable
- Logged in debug builds
- Safe when the referenced project no longer exists

If a project has been deleted, ignore the stale action and remove stale pending notifications when possible.

---

## 28. Error Handling

Use typed errors for domain behavior.

Examples:

```swift
enum ProjectError: Error, Equatable {
    case projectNotFound
    case emptyTitle
    case invalidStatusTransition(
        from: ProjectStatus,
        to: ProjectStatus
    )
    case activeProjectRecommendationExceeded(
        currentCount: Int,
        recommendedMaximum: Int
    )
}
```

```swift
enum NotificationError: Error {
    case permissionDenied
    case invalidReminderTime
    case schedulingFailed
}
```

Views should present understandable messages.

Do not expose technical implementation details such as SwiftData or notification request identifiers to users.

A notification failure must not prevent local project data from being saved.

Where appropriate:

1. Save valid project data.
2. Attempt notification synchronization.
3. Surface notification-specific errors separately.

---

## 29. Deletion Rules

Deleting a project must:

1. Ask for confirmation.
2. Cancel its pending notification.
3. Delete associated daily check-ins through the SwiftData cascade rule.
4. Save the model context.
5. Reconcile pending notifications.

Deletion is different from marking a project as `failed`.

Prefer preserving history through `failed` or `completed` unless the user explicitly chooses deletion.

---

## 30. Localization

Use a String Catalog:

```text
Localizable.xcstrings
```

Prefer generated symbol-based keys where supported.

Examples:

- `projectStatusInProgress`
- `dailyCheckInCompleted`
- `dailyCheckInNotCompleted`
- `dailyResultCannotBeChanged`
- `activeProjectLimitWarning`
- `notificationPermissionDenied`

Do not scatter hard-coded user-facing strings throughout feature code.

Initially support at least:

- English
- Simplified Chinese

When adding a user-facing string, update all supported localizations.

---

## 31. Testing Requirements

Core product rules require unit tests.

### 31.1 Project Status Tests

Test:

- All valid transitions
- All invalid transitions
- Terminal-state behavior
- Notification cancellation when leaving `inProgress`
- Notification scheduling when entering `inProgress`

### 31.2 Active Project Policy Tests

Test:

- Zero through three active projects
- Activating the third project
- Attempting to activate a fourth project
- Explicit continuation after warning
- No automatic pausing of another project

### 31.3 Daily Check-In Tests

Test:

- Creating today's pending check-in
- Returning an existing check-in rather than duplicating it
- Finalizing as completed
- Finalizing as not completed
- Rejecting a second finalization
- Rejecting changes from completed to not completed
- Rejecting changes from not completed to completed
- Rejecting future-day results
- Handling historical unresolved results
- Stable behavior across app relaunch

### 31.4 Calendar Tests

Use fixed calendars, time zones, and dates.

Test:

- Start-of-day normalization
- Daylight-saving transitions
- Time-zone changes
- Midnight boundaries
- Same instant represented in different time zones

Do not rely on `Date.now` directly in deterministic tests.

Inject a clock:

```swift
protocol DateProviding: Sendable {
    var now: Date { get }
}
```

### 31.5 Notification Tests

Mock notification scheduling.

Test:

- Correct deterministic identifier
- Correct project identifier in payload
- Correct reminder time
- Replacement after time change
- Cancellation after pause
- Cancellation after completion
- Cancellation after failure
- Orphan cleanup
- Duplicate action delivery
- Missing/deleted project action
- Permission-denied behavior

### 31.6 Persistence Tests

Use an in-memory SwiftData container.

Test:

- Project save and fetch
- Daily check-in relationship
- Cascade deletion
- Enum raw-value fallback
- Duplicate-day prevention at service level
- Finalized result persistence

Prefer unit tests to UI tests.

Only use UI tests where behavior cannot reasonably be verified through unit tests.

---

## 32. Preview Requirements

SwiftUI previews should use an in-memory SwiftData container.

Provide representative preview states:

- Empty project list
- Three active projects
- Projects in all statuses
- Pending daily result
- Completed daily result
- Not-completed daily result
- Notification permission denied
- Long localized text
- Large Dynamic Type size

Do not allow previews to write into the production data store.

---

## 33. Build and Validation Workflow

After making changes:

1. Format the code.
2. Run SwiftLint if installed.
3. Run unit tests.
4. Build the project.
5. Resolve warnings.
6. Inspect concurrency warnings.
7. Render relevant SwiftUI previews.
8. Check the Xcode Issue Navigator.

Do not report a task as complete when the project does not compile.

Do not leave placeholder fatal errors in production paths.

Do not disable tests to make a build pass.

---

## 34. Xcode MCP Usage

If Xcode MCP is configured, prefer its tools when working with this project.

Use:

- `DocumentationSearch` to verify API availability and usage.
- `BuildProject` after implementation.
- `GetBuildLog` for compiler errors and warnings.
- `RenderPreview` to inspect SwiftUI views.
- `XcodeListNavigatorIssues` to check project issues.
- `ExecuteSnippet` for focused API experiments.
- `XcodeRead` to inspect project files.
- `XcodeWrite` to create files.
- `XcodeUpdate` to modify files.

Prefer Xcode-aware tools over generic text editing for Xcode project changes.

When uncertain about a current Apple API, verify it with documentation before generating implementation code.

---

## 35. Implementation Order

Implement the app incrementally.

### Phase 1: Domain and Persistence

Create:

- Project status enum
- Daily check-in status enum
- SwiftData models
- Date normalization service
- Status transition policy
- Daily finalization policy
- In-memory persistence tests

### Phase 2: Basic Project Management

Create:

- Project list grouped by status
- Create-project flow
- Project detail
- Explicit status transitions
- Three-active-project recommendation
- Unit tests

### Phase 3: Daily Check-Ins

Create:

- Today's check-in resolution
- Completed/not-completed confirmation
- Immutable finalization
- History display
- Unit tests for all invariants

### Phase 4: Notifications

Create:

- Permission onboarding
- Notification categories
- Daily repeating reminders
- Notification actions
- Reconciliation
- Notification mock tests

### Phase 5: Polish

Add:

- Localization
- Accessibility
- Empty states
- Error presentation
- Dark Mode validation
- Dynamic Type validation
- Preview coverage

Do not attempt every phase in one unreviewed change.

Prefer small, compilable, testable commits.

---

## 36. Definition of Done

A feature is complete only when:

- The implementation matches the product rules.
- The project compiles.
- Relevant tests pass.
- No new warnings are introduced.
- Swift concurrency diagnostics are addressed.
- User-facing text is localized.
- Accessibility behavior is considered.
- SwiftUI previews cover important states.
- Notification changes are reconciled.
- Persistence changes are tested.
- Irreversible daily-result behavior cannot be bypassed.

---

## 37. Product Invariants

Never violate these invariants:

1. Every learning project has one valid project status.
2. Only `inProgress` projects receive daily reminders.
3. A project and local day have at most one daily check-in.
4. A daily check-in begins as `pending`.
5. A pending daily check-in may be finalized once.
6. A finalized daily check-in cannot be changed.
7. A future day cannot be finalized.
8. Future daily records are not pre-generated.
9. Repeating notifications do not imply pre-generated records.
10. Notification actions and in-app actions use the same domain finalization logic.
11. Notification action processing is idempotent.
12. Project lifecycle status and daily completion status remain separate concepts.
13. Activating more than three projects requires a warning.
14. The app never automatically chooses which project to pause.
15. SwiftUI views do not directly implement core business rules.

When a requested change conflicts with one of these invariants, stop and explain the conflict before implementing it.

---

## 38. Instructions for Claude Code

When receiving a development request:

1. Read this file first.
2. Inspect the existing project structure.
3. Inspect related models, services, tests, and views.
4. Describe the intended changes briefly.
5. Implement the smallest coherent change.
6. Do not rewrite unrelated files.
7. Preserve existing behavior unless the request explicitly changes it.
8. Add tests for new domain behavior.
9. Build and test the project.
10. Report:
   - Files changed
   - Important design decisions
   - Tests added or updated
   - Build and test results
   - Remaining limitations

Do not generate large amounts of speculative code before inspecting the repository.

Do not claim that code builds or tests pass unless the relevant commands or Xcode MCP tools were actually run successfully.
