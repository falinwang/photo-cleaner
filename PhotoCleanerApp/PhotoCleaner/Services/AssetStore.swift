import Foundation
import Observation

@Observable
class AssetStore {
    private enum Key {
        static let kept    = "keptForLaterIDs"
        static let trashed = "trashedIDs"
        static let sorted  = "sortedIDs"
    }

    // Each set persists only itself on change — a mutation no longer re-serializes all three.
    var keptForLaterIDs: Set<String> { didSet { persist(keptForLaterIDs, forKey: Key.kept) } }
    var trashedIDs: Set<String>      { didSet { persist(trashedIDs, forKey: Key.trashed) } }
    var sortedIDs: Set<String>       { didSet { persist(sortedIDs, forKey: Key.sorted) } }

    init() {
        // Assignments in init don't fire didSet, so this reads without writing back.
        let d = UserDefaults.standard
        keptForLaterIDs = Set(d.stringArray(forKey: Key.kept)    ?? [])
        trashedIDs      = Set(d.stringArray(forKey: Key.trashed) ?? [])
        sortedIDs       = Set(d.stringArray(forKey: Key.sorted)  ?? [])
    }

    func isUnsorted(_ id: String) -> Bool {
        !keptForLaterIDs.contains(id) && !trashedIDs.contains(id) && !sortedIDs.contains(id)
    }

    /// Clears all three buckets so every asset becomes Unsorted again.
    /// Does not touch Photos.app (no album removal, no favorite changes, no real deletes).
    func reset() {
        keptForLaterIDs = []
        trashedIDs = []
        sortedIDs = []
    }

    private func persist(_ ids: Set<String>, forKey key: String) {
        UserDefaults.standard.set(Array(ids), forKey: key)
    }
}
