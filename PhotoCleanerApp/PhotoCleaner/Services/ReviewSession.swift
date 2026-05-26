import Foundation
import Photos
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

    init(items: [MediaItem], startID: String? = nil) {
        self.items = items
        if let startID, let idx = items.firstIndex(where: { $0.id == startID }) {
            currentIndex = idx
        }
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
        guard let item = currentItem, let asset = item.asset else { return }
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest(for: asset).isFavorite = true
        }
        pushUndo(UndoRecord(item: item, removedAtIndex: currentIndex, actionLabel: "Favorite"))
        moveToNext()
    }

    func updateCloudStatus(_ status: CloudStatus, for id: String) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].cloudStatus = status
    }

    func undo(store: AssetStore) {
        guard let record = undoStack.popLast() else { return }
        switch record.actionLabel {
        case "Keep":   store.keptForLaterIDs.remove(record.item.id)
        case "Return": store.keptForLaterIDs.insert(record.item.id)
        case "Delete": store.trashedIDs.remove(record.item.id)
        case "Sort":   store.sortedIDs.remove(record.item.id)
        case "Favorite":
            if let asset = record.item.asset {
                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest(for: asset).isFavorite = false
                }
            }
            currentIndex = record.removedAtIndex
            return
        default: break
        }
        let insertAt = min(record.removedAtIndex, items.count)
        items.insert(record.item, at: insertAt)
        currentIndex = insertAt
    }

    // MARK: - Navigation

    func moveToNext() {
        guard currentIndex + 1 < items.count else { return }
        currentIndex += 1
    }

    func moveToPrevious() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
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
