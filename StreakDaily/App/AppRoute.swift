import Foundation

/// Typed navigation destinations (CLAUDE.md §20).
enum AppRoute: Hashable {
    case projectDetail(UUID)
}
