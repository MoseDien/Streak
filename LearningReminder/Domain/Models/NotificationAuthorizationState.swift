import Foundation
import UserNotifications

/// The app's view of notification authorization (CLAUDE.md §15.1).
enum NotificationAuthorizationState: Sendable, Equatable {
    case notDetermined
    case denied
    case authorized
    case provisional
    case ephemeral
}

extension NotificationAuthorizationState {
    init(_ status: UNAuthorizationStatus) {
        switch status {
        case .notDetermined: self = .notDetermined
        case .denied: self = .denied
        case .authorized: self = .authorized
        case .provisional: self = .provisional
        case .ephemeral: self = .ephemeral
        @unknown default: self = .notDetermined
        }
    }
}
