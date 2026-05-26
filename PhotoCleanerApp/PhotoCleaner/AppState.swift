import SwiftUI

enum AppMode: String, CaseIterable, Identifiable, Hashable {
    case onThisDay = "On This Day"
    case random = "Random"
    case unsorted = "Unsorted"
    case keptForLater = "Kept for Later"
    case largestFirst = "Largest First"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .onThisDay:    return "calendar.badge.clock"
        case .random:       return "shuffle"
        case .unsorted:     return "tray"
        case .keptForLater: return "bookmark"
        case .largestFirst: return "arrow.up.arrow.down"
        }
    }

    var description: String {
        switch self {
        case .onThisDay:    return "Photos from this date in past years"
        case .random:       return "Random picks from Unsorted"
        case .unsorted:     return "Everything not yet organized"
        case .keptForLater: return "Temporary bucket — review and return to Unsorted"
        case .largestFirst: return "Videos first, sorted by file size — recover the most space"
        }
    }
}

@Observable
class AppState {
    var activeMode: AppMode? = nil
}
