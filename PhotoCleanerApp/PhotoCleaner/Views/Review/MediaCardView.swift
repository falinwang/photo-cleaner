import SwiftUI
import Photos

struct MediaCardView: View {
    let item: MediaItem
    var onCloudStatusUpdate: ((CloudStatus) -> Void)? = nil

    @State private var image: UIImage? = nil
    @State private var imageRequestID: PHImageRequestID? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            imageLayer
            badgeRow
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear  { loadImage() }
        .onDisappear { cancelRequest() }
    }

    // MARK: - Image layer

    @ViewBuilder
    private var imageLayer: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(colors: placeholderColors, startPoint: .topLeading, endPoint: .bottomTrailing)
            ProgressView().tint(.white.opacity(0.5))
        }
    }

    // MARK: - Badge row

    private var badgeRow: some View {
        HStack(spacing: 8) {
            MediaTypeBadge(mediaType: item.mediaType)
            CloudStatusBadge(status: item.cloudStatus)
            Spacer()
            if let size = item.formattedFileSize {
                Text(size)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.5), in: Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 0.5))
            }
        }
        .padding(12)
        .background(
            LinearGradient(colors: [.black.opacity(0.7), .clear], startPoint: .bottom, endPoint: .top)
        )
    }

    // MARK: - PhotoKit loading

    private func loadImage() {
        guard let asset = item.asset else { return }

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true

        let scale = UIScreen.main.scale
        let size  = CGSize(width: UIScreen.main.bounds.width * scale,
                           height: UIScreen.main.bounds.height * scale)

        imageRequestID = PHImageManager.default().requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFit,
            options: options
        ) { result, info in
            guard let result else { return }
            DispatchQueue.main.async {
                self.image = result
                let isInCloud = info?[PHImageResultIsInCloudKey] as? Bool ?? false
                onCloudStatusUpdate?(isInCloud ? .iCloudOnly : .local)
            }
        }
    }

    private func cancelRequest() {
        if let id = imageRequestID {
            PHImageManager.default().cancelImageRequest(id)
        }
    }

    // MARK: - Placeholder colors

    private var placeholderColors: [Color] {
        switch item.mediaType {
        case .photo:      return [Color(white: 0.2), Color(white: 0.12)]
        case .video:      return [Color.purple.opacity(0.35), Color.black]
        case .screenshot: return [Color.orange.opacity(0.25), Color.black]
        case .other:      return [Color.gray.opacity(0.25), Color.black]
        }
    }
}

#Preview {
    MediaCardView(item: MediaItem.mockItems[0])
        .frame(height: 480)
        .padding()
        .background(.black)
}
