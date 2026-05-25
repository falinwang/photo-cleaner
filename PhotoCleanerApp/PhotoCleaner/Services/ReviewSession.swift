import Foundation
import Observation

struct UndoRecord {
    let item: MediaItem
    let removedAtIndex: Int
    let actionLabel: String
}

@Observable
class ReviewSession {
    private(set) var items: [MediaItem]
    private(set) var currentIndex: Int = 0
    private(set) var undoStack: [UndoRecord] = []
    private let maxUndo = 20

    var currentItem: MediaItem? {
        guard !items.isEmpty, currentIndex < items.count else { return nil }
        return items[currentIndex]
    }

    var progressText: String {
        guard !items.isEmpty else { return "0/0" }
        return "\(min(currentIndex + 1, items.count))/\(items.count)"
    }

    var canUndo: Bool { !undoStack.isEmpty }
    var undoCount: Int { undoStack.count }
    var isEmpty: Bool { items.isEmpty }

    init(items: [MediaItem]) {
        self.items = items
    }

    // MARK: - Actions

    func skip() {
        // Skip is not stateful — no undo record
        guard !items.isEmpty else { return }
        let item = items.remove(at: currentIndex)
        items.append(item)
        if currentIndex >= items.count { currentIndex = 0 }
    }

    func keep(store: AssetStore) {
        guard let item = currentItem else { return }
        pushUndo(UndoRecord(item: item, removedAtIndex: currentIndex, actionLabel: "Keep"))
        store.keptForLaterIDs.insert(item.id)
        removeCurrentAndAdjust()
    }

    func returnToUnsorted(store: AssetStore) {
        guard let item = currentItem else { return }
        pushUndo(UndoRecord(item: item, removedAtIndex: currentIndex, actionLabel: "Return"))
        store.keptForLaterIDs.remove(item.id)
        removeCurrentAndAdjust()
    }

    func delete(store: AssetStore) {
        guard let item = currentItem else { return }
        pushUndo(UndoRecord(item: item, removedAtIndex: currentIndex, actionLabel: "Delete"))
        store.trashedIDs.insert(item.id)
        removeCurrentAndAdjust()
    }

    func sortToAlbum(albumID: String, store: AssetStore) {
        guard let item = currentItem else { return }
        pushUndo(UndoRecord(item: item, removedAtIndex: currentIndex, actionLabel: "Sort"))
        store.sortedIDs.insert(item.id)
        removeCurrentAndAdjust()
    }

    func favorite() {
        // PhotoKit write happens in M2
    }

    func updateCloudStatus(_ status: CloudStatus, for id: String) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].cloudStatus = status
    }

    func undo(store: AssetStore) {
        guard let record = undoStack.popLast() else { return }
        store.keptForLaterIDs.remove(record.item.id)
        store.trashedIDs.remove(record.item.id)
        store.sortedIDs.remove(record.item.id)
        let insertAt = min(record.removedAtIndex, items.count)
        items.insert(record.item, at: insertAt)
        currentIndex = insertAt
    }

    // MARK: - Helpers

    private func pushUndo(_ record: UndoRecord) {
        undoStack.append(record)
        if undoStack.count > maxUndo { undoStack.removeFirst() }
    }

    private func removeCurrentAndAdjust() {
        guard currentIndex < items.count else { return }
        items.remove(at: currentIndex)
        guard !items.isEmpty else { return }
        if currentIndex >= items.count { currentIndex = items.count - 1 }
    }
}
