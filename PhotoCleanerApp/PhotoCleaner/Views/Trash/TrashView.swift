import SwiftUI
import Photos

struct TrashView: View {
    @Environment(AssetStore.self) private var assetStore
    @Environment(\.dismiss) private var dismiss

    @State private var thumbnails: [String: UIImage] = [:]
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 4)

    var body: some View {
        VStack(spacing: 0) {
            header

            if assetStore.trashedIDs.isEmpty {
                emptyState
            } else {
                photoGrid
                bottomBar
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog(
            "Delete \(assetStore.trashedIDs.count) photo\(assetStore.trashedIDs.count == 1 ? "" : "s")?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { permanentlyDeleteAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("They will be in Recently Deleted for 30 days.")
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 6) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.white.opacity(0.1), in: Circle())
                }
                Spacer()
                Text("TRASH")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .kerning(1.5)
                Spacer()
                // Spacer to balance the X button
                Color.clear.frame(width: 36, height: 36)
            }
            .padding(.horizontal)
            .padding(.top, 4)

            Text("Delete photos to free up space on your device!")
                .font(.caption)
                .foregroundStyle(.gray)
                .padding(.bottom, 8)
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: "trash")
                    .font(.system(size: 56))
                    .foregroundStyle(.white.opacity(0.2))
                Text("Trash is empty")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Text("Photos you delete will appear here\nbefore being permanently removed.")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Spacer()
        }
    }

    // MARK: - Photo grid

    private var photoGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Array(assetStore.trashedIDs), id: \.self) { itemID in
                    TrashThumbnailCell(itemID: itemID, thumbnail: thumbnails[itemID])
                        .onAppear { loadThumbnail(for: itemID) }
                }
            }
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 10) {
            Divider().background(.white.opacity(0.1))
            HStack(spacing: 12) {
                Button(action: recoverAll) {
                    Text("RECOVER ALL")
                        .font(.subheadline.weight(.bold))
                        .kerning(0.5)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                }

                Button(action: { showDeleteConfirm = true }) {
                    HStack(spacing: 6) {
                        if isDeleting {
                            ProgressView().tint(.white).scaleEffect(0.8)
                        }
                        Text("DELETE ALL")
                            .font(.subheadline.weight(.bold))
                            .kerning(0.5)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.red, in: RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isDeleting)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color.black)
    }

    // MARK: - Actions

    private func recoverAll() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        assetStore.trashedIDs.removeAll()
    }

    private func permanentlyDeleteAll() {
        isDeleting = true
        let ids = Array(assetStore.trashedIDs)

        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        var assets: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in assets.append(asset) }

        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assets as NSFastEnumeration)
        }) { success, _ in
            DispatchQueue.main.async {
                isDeleting = false
                if success {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    assetStore.trashedIDs.removeAll()
                }
            }
        }
    }

    // MARK: - Thumbnail loading

    private func loadThumbnail(for id: String) {
        guard thumbnails[id] == nil else { return }

        let result = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
        guard let asset = result.firstObject else { return }

        let size = CGSize(width: 120, height: 120)
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.isNetworkAccessAllowed = false

        PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { image, _ in
            guard let image else { return }
            DispatchQueue.main.async { thumbnails[id] = image }
        }
    }
}

// MARK: - Thumbnail cell

private struct TrashThumbnailCell: View {
    let itemID: String
    let thumbnail: UIImage?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let thumb = thumbnail {
                    Image(uiImage: thumb)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.width)
                        .clipped()
                } else {
                    Color(white: 0.15)
                    ProgressView().tint(.white.opacity(0.4)).scaleEffect(0.7)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    TrashView()
        .environment(AssetStore())
}
