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

    func fetchItems(for mode: AppMode, store: AssetStore) -> [MediaItem] {
        switch mode {
        case .keptForLater:
            return fetchKeptForLater(store: store)
        default:
            return fetchGeneral(mode: mode, store: store)
        }
    }

    // MARK: - Private fetch helpers

    private func fetchGeneral(mode: AppMode, store: AssetStore) -> [MediaItem] {
        let options = PHFetchOptions()
        options.includeHiddenAssets = false
        options.includeAllBurstAssets = false

        switch mode {
        case .unsorted:
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        case .onThisDay:
            options.predicate = onThisDayPredicate()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        case .random:
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        default:
            break
        }

        let result = PHAsset.fetchAssets(with: options)
        var items: [MediaItem] = []
        result.enumerateObjects { asset, _, _ in
            guard store.isUnsorted(asset.localIdentifier) else { return }
            items.append(self.makeItem(from: asset))
        }

        if mode == .random { items.shuffle() }
        return items
    }

    private func fetchKeptForLater(store: AssetStore) -> [MediaItem] {
        let ids = Array(store.keptForLaterIDs)
        guard !ids.isEmpty else { return [] }
        let result = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        var items: [MediaItem] = []
        result.enumerateObjects { asset, _, _ in
            items.append(self.makeItem(from: asset))
        }
        return items
    }

    // MARK: - Item construction

    private func makeItem(from asset: PHAsset) -> MediaItem {
        MediaItem(
            id: asset.localIdentifier,
            asset: asset,
            mediaType: Self.mediaType(from: asset),
            cloudStatus: .local,        // refined at image-load time via PHImageResultIsInCloudKey
            fileSize: Self.fileSize(from: asset),
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

    private func onThisDayPredicate() -> NSPredicate {
        let calendar = Calendar.current
        let today = Date()
        let month = calendar.component(.month, from: today)
        let day   = calendar.component(.day,   from: today)
        let currentYear = calendar.component(.year, from: today)

        var subs: [NSPredicate] = []
        for year in max(currentYear - 10, 2000)..<currentYear {
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
