import Photos
import Observation

@Observable
class PhotoLibraryService {
    private(set) var authorizationStatus: PHAuthorizationStatus

    init() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestAuthorization() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await MainActor.run { authorizationStatus = status }
    }

    // MARK: - Fetch

    /// Synchronous fetch. Heavy for large libraries — prefer `loadItems` off the main thread.
    func fetchItems(for mode: AppMode, store: AssetStore, mediaFilter: MediaFilter = .all) -> [MediaItem] {
        Self.buildItems(for: mode, snapshot: LibrarySnapshot(store: store), mediaFilter: mediaFilter)
    }

    /// Async fetch. Snapshots the organize-state on the caller's actor, then enumerates the
    /// photo library — and, for Largest First, reads per-asset file sizes — off the main thread.
    func loadItems(for mode: AppMode, store: AssetStore, mediaFilter: MediaFilter = .all) async -> [MediaItem] {
        let snapshot = LibrarySnapshot(store: store)
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: Self.buildItems(for: mode, snapshot: snapshot, mediaFilter: mediaFilter))
            }
        }
    }

    func fetchOnThisDayGrouped(store: AssetStore) -> [YearGroup] {
        let options = PHFetchOptions()
        options.includeHiddenAssets = false
        options.includeAllBurstAssets = false
        options.predicate = Self.onThisDayPredicate()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let result = PHAsset.fetchAssets(with: options)
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        var itemsByYear: [Int: [MediaItem]] = [:]

        result.enumerateObjects { asset, _, _ in
            guard store.isUnsorted(asset.localIdentifier),
                  let date = asset.creationDate else { return }
            let assetYear = calendar.component(.year, from: date)
            guard assetYear < currentYear else { return }
            itemsByYear[assetYear, default: []].append(Self.makeItem(from: asset))
        }

        return itemsByYear
            .map { year, items in
                YearGroup(
                    year: year,
                    yearOffset: currentYear - year,
                    items: items.sorted { ($0.creationDate ?? .distantPast) > ($1.creationDate ?? .distantPast) }
                )
            }
            .sorted { $0.year > $1.year }
    }

    // MARK: - Store snapshot

    /// Immutable, `Sendable` snapshot of the organize-state sets, captured on the caller's
    /// actor so the heavy library enumeration can safely run on a background queue.
    struct LibrarySnapshot: Sendable {
        let kept: Set<String>
        let trashed: Set<String>
        let sorted: Set<String>

        init(store: AssetStore) {
            kept = store.keptForLaterIDs
            trashed = store.trashedIDs
            sorted = store.sortedIDs
        }

        func isUnsorted(_ id: String) -> Bool {
            !kept.contains(id) && !trashed.contains(id) && !sorted.contains(id)
        }
    }

    // MARK: - Private fetch helpers

    private static func buildItems(for mode: AppMode, snapshot: LibrarySnapshot, mediaFilter: MediaFilter) -> [MediaItem] {
        switch mode {
        case .keptForLater:
            return buildKeptForLater(snapshot: snapshot)
        default:
            return buildGeneral(mode: mode, snapshot: snapshot, mediaFilter: mediaFilter)
        }
    }

    private static func buildGeneral(mode: AppMode, snapshot: LibrarySnapshot, mediaFilter: MediaFilter) -> [MediaItem] {
        let options = PHFetchOptions()
        options.includeHiddenAssets = false
        options.includeAllBurstAssets = false

        switch mode {
        case .unsorted, .largestFirst:
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        case .onThisDay:
            options.predicate = onThisDayPredicate()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        case .random:
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        default:
            break
        }

        let result: PHFetchResult<PHAsset>
        if mode == .unsorted {
            switch mediaFilter {
            case .all:
                result = PHAsset.fetchAssets(with: options)
            case .videos:
                result = PHAsset.fetchAssets(with: .video, options: options)
            case .screenshots:
                let screenshotPred = NSPredicate(format: "mediaSubtype & %d != 0", PHAssetMediaSubtype.photoScreenshot.rawValue)
                if let existing = options.predicate {
                    options.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [existing, screenshotPred])
                } else {
                    options.predicate = screenshotPred
                }
                result = PHAsset.fetchAssets(with: .image, options: options)
            }
        } else {
            result = PHAsset.fetchAssets(with: options)
        }

        var items: [MediaItem] = []
        result.enumerateObjects { asset, _, _ in
            guard snapshot.isUnsorted(asset.localIdentifier) else { return }
            if mode == .largestFirst {
                let size = fileSize(from: asset)
                items.append(MediaItem(
                    id: asset.localIdentifier,
                    asset: asset,
                    mediaType: mediaType(from: asset),
                    cloudStatus: .local,
                    fileSize: size,
                    fileSizeIsEstimated: size == nil,
                    creationDate: asset.creationDate
                ))
            } else {
                items.append(makeItem(from: asset))
            }
        }

        switch mode {
        case .random: items.shuffle()
        case .largestFirst:
            items.sort { a, b in
                if a.mediaType != b.mediaType {
                    return a.mediaType == .video
                }
                return (a.fileSize ?? 0) > (b.fileSize ?? 0)
            }
        default: break
        }
        return items
    }

    private static func buildKeptForLater(snapshot: LibrarySnapshot) -> [MediaItem] {
        let ids = Array(snapshot.kept)
        guard !ids.isEmpty else { return [] }
        let result = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        var items: [MediaItem] = []
        result.enumerateObjects { asset, _, _ in
            items.append(makeItem(from: asset))
        }
        return items
    }

    // MARK: - Item construction

    private static func makeItem(from asset: PHAsset) -> MediaItem {
        MediaItem(
            id: asset.localIdentifier,
            asset: asset,
            mediaType: Self.mediaType(from: asset),
            cloudStatus: .local,
            fileSize: nil,              // loaded lazily per card — avoids main-thread watchdog
            fileSizeIsEstimated: false,
            creationDate: asset.creationDate
        )
    }

    // MARK: - Helpers

    static func mediaType(from asset: PHAsset) -> MediaType {
        if asset.mediaSubtypes.contains(.photoScreenshot) { return .screenshot }
        switch asset.mediaType {
        case .image: return .photo
        case .video: return .video
        default:     return .other
        }
    }

    static func fileSize(from asset: PHAsset) -> Int64? {
        let resources = PHAssetResource.assetResources(for: asset)
        let primary: Set<PHAssetResourceType> = [.photo, .video, .fullSizePhoto, .fullSizeVideo]
        for resource in resources where primary.contains(resource.type) {
            if let size = resource.value(forKey: "fileSize") as? Int64, size > 0 {
                return size
            }
        }
        return nil
    }

    private static func onThisDayPredicate() -> NSPredicate {
        let calendar = Calendar.current
        let today = Date()
        let month = calendar.component(.month, from: today)
        let day   = calendar.component(.day,   from: today)
        let currentYear = calendar.component(.year, from: today)

        var subs: [NSPredicate] = []
        for year in 1970..<currentYear {
            var comps = DateComponents()
            comps.year = year; comps.month = month; comps.day = day
            comps.hour = 0; comps.minute = 0; comps.second = 0
            guard let start = calendar.date(from: comps),
                  let end   = calendar.date(byAdding: .day, value: 1, to: start) else { continue }
            subs.append(NSPredicate(format: "creationDate >= %@ AND creationDate < %@",
                                    start as NSDate, end as NSDate))
        }
        return subs.isEmpty
            ? NSPredicate(value: false)
            : NSCompoundPredicate(orPredicateWithSubpredicates: subs)
    }
}
