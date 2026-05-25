import Foundation
import Observation

@Observable
class AssetStore {
    var keptForLaterIDs: Set<String> { didSet { persist() } }
    var trashedIDs: Set<String>      { didSet { persist() } }
    var sortedIDs: Set<String>       { didSet { persist() } }

    init() {
        let d = UserDefaults.standard
        keptForLaterIDs = Set(d.stringArray(forKey: "keptForLaterIDs") ?? [])
        trashedIDs      = Set(d.stringArray(forKey: "trashedIDs")      ?? [])
        sortedIDs       = Set(d.stringArray(forKey: "sortedIDs")       ?? [])
    }

    func isUnsorted(_ id: String) -> Bool {
        !keptForLaterIDs.contains(id) && !trashedIDs.contains(id) && !sortedIDs.contains(id)
    }

    private func persist() {
        let d = UserDefaults.standard
        d.set(Array(keptForLaterIDs), forKey: "keptForLaterIDs")
        d.set(Array(trashedIDs),      forKey: "trashedIDs")
        d.set(Array(sortedIDs),       forKey: "sortedIDs")
    }
}
