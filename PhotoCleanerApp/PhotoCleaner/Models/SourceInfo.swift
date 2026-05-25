import Foundation

enum VersionStage: String, CaseIterable, Codable {
    case unknown          = "Unknown"
    case original         = "Original"
    case lightroomExport  = "Lightroom Export"
    case meituEdit        = "Meitu Edit"
    case instagramVersion = "Instagram Version"
    case xVersion         = "X Version"
    case otherEdit        = "Other Edit"
}

struct SourceInfo: Codable, Equatable {
    var versionStage: VersionStage = .unknown
    var notes: String = ""

    private static let keyPrefix = "source_"

    static func load(for id: String) -> SourceInfo {
        guard let data = UserDefaults.standard.data(forKey: keyPrefix + id),
              let info = try? JSONDecoder().decode(SourceInfo.self, from: data)
        else { return SourceInfo() }
        return info
    }

    func save(for id: String) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.keyPrefix + id)
    }
}
