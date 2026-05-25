import Foundation

enum TaskState: String, Codable {
    case unsorted
    case keptForLater
    case sorted
    case trashed
    // "skipped" is not a persisted state — the queue pointer advances but the item stays in Unsorted
}
