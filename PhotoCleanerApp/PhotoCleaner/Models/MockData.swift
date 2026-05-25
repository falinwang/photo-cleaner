import Foundation

extension MediaItem {
    static let mockItems: [MediaItem] = [
        MediaItem(id: "mock-001", asset: nil, mediaType: .video,      cloudStatus: .local,      fileSize: 248_000_000, fileSizeIsEstimated: false, creationDate: Calendar.current.date(byAdding: .day,  value: -3,  to: Date())),
        MediaItem(id: "mock-002", asset: nil, mediaType: .photo,      cloudStatus: .iCloudOnly, fileSize: 4_200_000,   fileSizeIsEstimated: false, creationDate: Calendar.current.date(byAdding: .day,  value: -10, to: Date())),
        MediaItem(id: "mock-003", asset: nil, mediaType: .screenshot, cloudStatus: .local,      fileSize: 1_800_000,   fileSizeIsEstimated: false, creationDate: Calendar.current.date(byAdding: .hour, value: -2,  to: Date())),
        MediaItem(id: "mock-004", asset: nil, mediaType: .photo,      cloudStatus: .local,      fileSize: 6_500_000,   fileSizeIsEstimated: false, creationDate: Calendar.current.date(byAdding: .day,  value: -30, to: Date())),
        MediaItem(id: "mock-005", asset: nil, mediaType: .video,      cloudStatus: .downloading, fileSize: 512_000_000, fileSizeIsEstimated: true, creationDate: Calendar.current.date(byAdding: .day,  value: -60, to: Date())),
        MediaItem(id: "mock-006", asset: nil, mediaType: .other,      cloudStatus: .failed,     fileSize: nil,         fileSizeIsEstimated: false, creationDate: nil),
    ]
}

struct MockAlbum: Identifiable {
    let id: String
    let name: String
    let emoji: String

    static let mockAlbums: [MockAlbum] = [
        MockAlbum(id: "a1", name: "布達娜娜", emoji: "🐱"),
        MockAlbum(id: "a2", name: "萌寵",    emoji: "🐶"),
        MockAlbum(id: "a3", name: "存圖飯拍", emoji: "📷"),
        MockAlbum(id: "a4", name: "HD 高清",  emoji: "📹"),
        MockAlbum(id: "a5", name: "剪片",     emoji: "✂️"),
        MockAlbum(id: "a6", name: "旅遊",     emoji: "✈️"),
    ]
}
