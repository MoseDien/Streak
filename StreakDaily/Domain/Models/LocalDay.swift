import Foundation

/// A normalized local calendar day, identified by its start-of-day instant
/// (CLAUDE.md §12).
///
/// Daily records are identified and compared by calendar day, never by raw
/// timestamps. Two `LocalDay` values produced by the same calendar provider
/// compare correctly because they share a consistent start-of-day definition.
struct LocalDay: Hashable, Sendable {
    let startOfDay: Date

    init(startOfDay: Date) {
        self.startOfDay = startOfDay
    }
}

extension LocalDay: Comparable {
    static func < (lhs: LocalDay, rhs: LocalDay) -> Bool {
        lhs.startOfDay < rhs.startOfDay
    }
}
