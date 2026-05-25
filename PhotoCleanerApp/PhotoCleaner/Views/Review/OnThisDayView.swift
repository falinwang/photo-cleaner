import SwiftUI
import Photos

struct OnThisDayView: View {
    let groups: [YearGroup]
    @Environment(AssetStore.self) private var assetStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedGroup: YearGroup? = nil
    @State private var startItemID: String? = nil
    @State private var thumbnails: [String: UIImage] = [:]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if groups.isEmpty {
                emptyState
            } else {
                groupList
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $selectedGroup) { group in
            ReviewView(
                mode: .onThisDay,
                session: ReviewSession(items: group.items, startID: startItemID)
            )
        }
    }

    // MARK: - Group list

    private var groupList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                VStack(spacing: 24) {
                    ForEach(groups) { group in
                        yearSection(group)
                    }
                }
                .padding(.bottom, 32)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("On This Day")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Text(Date.now.formatted(date: .complete, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.1), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.top, 56)
        .padding(.bottom, 24)
    }

    // MARK: - Year section

    private func yearSection(_ group: YearGroup) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(group.label)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(group.items.count) item\(group.items.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(group.items) { item in
                    thumbnailCell(for: item, in: group)
                        .onAppear { loadThumbnail(for: item) }
                }
            }
        }
    }

    private func thumbnailCell(for item: MediaItem, in group: YearGroup) -> some View {
        GeometryReader { geo in
            Button {
                startItemID = item.id
                selectedGroup = group
            } label: {
                ZStack {
                    if let thumb = thumbnails[item.id] {
                        Image(uiImage: thumb)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.width)
                            .clipped()
                    } else {
                        Color(white: 0.15)
                        ProgressView().tint(.white.opacity(0.4)).scaleEffect(0.7)
                    }

                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: item.mediaType.icon)
                                .font(.caption2)
                                .foregroundStyle(.white)
                                .padding(3)
                                .background(.black.opacity(0.5), in: Circle())
                            Spacer()
                            if item.mediaType == .video {
                                Image(systemName: "play.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.white)
                                    .padding(3)
                                    .background(.black.opacity(0.5), in: Circle())
                            }
                        }
                        .padding(4)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.white.opacity(0.1), in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.top, 4)

            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 64))
                    .foregroundStyle(.white.opacity(0.25))
                VStack(spacing: 8) {
                    Text("No memories for today")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text("No photos or videos found for this date in past years.")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                Button(action: { dismiss() }) {
                    Text("Back to Home")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.white, in: Capsule())
                }
                .padding(.top, 8)
            }

            Spacer()
        }
    }

    // MARK: - Thumbnail loading

    private func loadThumbnail(for item: MediaItem) {
        guard thumbnails[item.id] == nil, let asset = item.asset else { return }

        let size = CGSize(width: 180, height: 180)
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            guard let image else { return }
            DispatchQueue.main.async { thumbnails[item.id] = image }
        }
    }
}

#Preview("With data") {
    NavigationStack {
        OnThisDayView(groups: [
            YearGroup(year: 2025, yearOffset: 1, items: Array(MediaItem.mockItems.prefix(3))),
            YearGroup(year: 2024, yearOffset: 2, items: Array(MediaItem.mockItems.prefix(2))),
            YearGroup(year: 2023, yearOffset: 3, items: Array(MediaItem.mockItems.suffix(2))),
        ])
        .environment(AssetStore())
    }
}

#Preview("Empty") {
    NavigationStack {
        OnThisDayView(groups: [])
            .environment(AssetStore())
    }
}
