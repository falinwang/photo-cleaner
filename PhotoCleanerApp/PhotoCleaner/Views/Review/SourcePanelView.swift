import SwiftUI
import Photos

struct SourcePanelView: View {
    let item: MediaItem
    @State private var versionStage: VersionStage
    @State private var notes: String

    init(item: MediaItem) {
        self.item = item
        let info = SourceInfo.load(for: item.id)
        _versionStage = State(initialValue: info.versionStage)
        _notes = State(initialValue: info.notes)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Version stage
                VStack(alignment: .leading, spacing: 6) {
                    Text("Version")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.gray)
                    Picker("Version", selection: $versionStage) {
                        ForEach(VersionStage.allCases, id: \.self) { stage in
                            Text(stage.rawValue).tag(stage)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.white)
                }

                // Notes
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notes")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.gray)
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                        .lineLimit(2...4)
                }

                Divider().background(.white.opacity(0.1))

                // Read-only metadata
                metadataSection
            }
            .padding(14)
        }
        .frame(maxHeight: 220)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
        .onDisappear {
            SourceInfo(versionStage: versionStage, notes: notes).save(for: item.id)
        }
    }

    // MARK: - Metadata

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Metadata")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.gray)

            if let date = item.creationDate {
                row("Date", date.formatted(date: .abbreviated, time: .shortened))
            }
            row("Type", item.mediaType.rawValue)
            if let size = item.formattedFileSize ?? lazyFileSize {
                row("Size", size)
            }
            if let asset = item.asset {
                row("Source", sourceLabel(for: asset.sourceType))
                let tags = subtypeTags(for: asset.mediaSubtypes)
                if tags != "None" { row("Tags", tags) }
                row("Resolution", "\(asset.pixelWidth)×\(asset.pixelHeight)")
            }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.gray)
                .frame(width: 64, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
            Spacer()
        }
    }

    private var lazyFileSize: String? {
        guard let asset = item.asset,
              let size = PhotoLibraryService.fileSize(from: asset) else { return nil }
        if size >= 1_000_000 {
            return String(format: "%.1f MB", Double(size) / 1_000_000)
        }
        return String(format: "%.0f KB", Double(size) / 1_000)
    }

    private func sourceLabel(for type: PHAssetSourceType) -> String {
        switch type {
        case .typeUserLibrary: return "Camera / Saved"
        case .typeCloudShared: return "iCloud Shared"
        case .typeiTunesSynced: return "iTunes Synced"
        default: return "Other"
        }
    }

    private func subtypeTags(for subtypes: PHAssetMediaSubtype) -> String {
        var tags: [String] = []
        if subtypes.contains(.photoScreenshot)    { tags.append("Screenshot") }
        if subtypes.contains(.photoPanorama)      { tags.append("Panorama") }
        if subtypes.contains(.photoHDR)           { tags.append("HDR") }
        if subtypes.contains(.photoLive)          { tags.append("Live") }
        if subtypes.contains(.photoDepthEffect)   { tags.append("Depth") }
        if subtypes.contains(.videoStreamed)       { tags.append("Streamed") }
        if subtypes.contains(.videoHighFrameRate) { tags.append("High FPS") }
        if subtypes.contains(.videoTimelapse)     { tags.append("Timelapse") }
        return tags.isEmpty ? "None" : tags.joined(separator: ", ")
    }
}

#Preview {
    VStack(spacing: 12) {
        SourcePanelView(item: MediaItem.mockItems[0])
    }
    .padding()
    .background(.black)
}
