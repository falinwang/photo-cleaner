import Foundation
import Photos

enum MediaFilter: String, CaseIterable, Identifiable {
    case all         = "All"
    case videos      = "Videos"
    case screenshots = "Screenshots"

    var id: String { rawValue }
}

enum MediaType: String {
    case photo      = "Photo"
    case video      = "Video"
    case screenshot = "Screenshot"
    case other      = "Other"

    var icon: String {
        switch self {
        case .photo:      return "photo"
        case .video:      return "video"
        case .screenshot: return "iphone"
        case .other:      return "doc"
        }
    }
}

enum CloudStatus: String {
    case local       = "Local"
    case iCloudOnly  = "iCloud"
    case downloading = "Downloading"
    case failed      = "Unavailable"

    var icon: String {
        switch self {
        case .local:       return "checkmark.icloud"
        case .iCloudOnly:  return "icloud"
        case .downloading: return "icloud.and.arrow.down"
        case .failed:      return "xmark.icloud"
        }
    }
}

struct MediaItem: Identifiable {
    let id: String
    let asset: PHAsset?             // nil only for mock/preview items
    let mediaType: MediaType
    var cloudStatus: CloudStatus
    var fileSize: Int64?            // bytes; nil = unknown — loaded lazily per card
    let fileSizeIsEstimated: Bool
    let creationDate: Date?

    var formattedFileSize: String? {
        guard let bytes = fileSize else { return nil }
        let prefix = fileSizeIsEstimated ? "~" : ""
        if bytes >= 1_000_000 {
            return "\(prefix)\(String(format: "%.1f", Double(bytes) / 1_000_000)) MB"
        }
        return "\(prefix)\(String(format: "%.0f", Double(bytes) / 1_000)) KB"
    }

    var formattedDate: String {
        guard let date = creationDate else { return "Unknown date" }
        return Self.dateFormatter.string(from: date)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()
}
