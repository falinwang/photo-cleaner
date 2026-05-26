import SwiftUI
import Photos
import AVFoundation
import AVKit
import UIKit

struct MediaCardView: View {
    let item: MediaItem
    var onCloudStatusUpdate: ((CloudStatus) -> Void)? = nil

    @State private var image: UIImage? = nil
    @State private var imageRequestID: PHImageRequestID? = nil
    @State private var player: AVPlayer? = nil
    @State private var videoRequestID: PHImageRequestID? = nil
    @State private var timeObserver: Any? = nil
    @State private var isPlaying = false
    @State private var lazyFileSize: String? = nil

    // Video controls
    @State private var showControls = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isSeeking = false
    @State private var showFullScreen = false

    private var isVideo: Bool { item.mediaType == .video }

    var body: some View {
        ZStack(alignment: .bottom) {
            mediaLayer
            badgeRow
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear  { loadMedia() }
        .onDisappear { cancelRequest() }
        .fullScreenCover(isPresented: $showFullScreen) {
            FullScreenVideoView(player: player, isPlaying: isPlaying) {
                // Restore inline state when returning from full screen
                isPlaying = $0
                showControls = true
            }
        }
    }

    // MARK: - Media layer

    @ViewBuilder
    private var mediaLayer: some View {
        if isVideo {
            if let player {
                ZStack {
                    PlayerView(player: player)

                    // Tap anywhere to toggle controls
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.15)) { showControls.toggle() }
                            if showControls { scheduleAutoHide() }
                        }

                    // Controls overlay
                    if showControls {
                        videoControlsOverlay(player: player)
                            .transition(.opacity)
                    }

                    // Big play button when paused and controls hidden
                    if !isPlaying && !showControls {
                        Button(action: { togglePlayback() }) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.4), radius: 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                placeholder
            }
        } else if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            placeholder
        }
    }

    // MARK: - Video controls overlay

    private func videoControlsOverlay(player: AVPlayer) -> some View {
        VStack(spacing: 0) {
            Spacer()

            // Progress bar + time labels
            VStack(spacing: 4) {
                Slider(
                    value: $currentTime,
                    in: 0...max(duration, 0.01),
                    onEditingChanged: { editing in
                        isSeeking = editing
                        if editing {
                            player.pause()
                        } else {
                            let target = CMTime(seconds: currentTime, preferredTimescale: 600)
                            player.seek(to: target)
                            if isPlaying { player.play() }
                        }
                    }
                )
                .tint(.white)
                .scaleEffect(0.9)

                HStack {
                    Text(timeString(currentTime))
                    Spacer()
                    Text(timeString(duration))
                }
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 4)

            // Bottom row: play/pause + fullscreen
            HStack {
                Button(action: { togglePlayback() }) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: { enterFullScreen() }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 6)
        }
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.6), .black.opacity(0.8)],
                startPoint: .top, endPoint: .bottom
            )
        )
    }

    // MARK: - Full screen

    private func enterFullScreen() {
        showFullScreen = true
    }

    // MARK: - Time tracking

    /// Periodic observer owned by the player: fires only for videos and only while playback
    /// advances — no ticks on photo cards or while paused. Removed in `cancelRequest`.
    private func addTimeObserver(to player: AVPlayer) {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: 600),
            queue: .main
        ) { time in
            guard !self.isSeeking else { return }
            let t = CMTimeGetSeconds(time)
            if t.isFinite { self.currentTime = t }
            if self.duration == 0, let item = player.currentItem {
                let d = CMTimeGetSeconds(item.duration)
                if d.isFinite { self.duration = d }
            }
        }
    }

    private func scheduleAutoHide() {
        guard isPlaying else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if isPlaying && showControls {
                withAnimation(.easeOut(duration: 0.2)) { showControls = false }
            }
        }
    }

    private func timeString(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "0:00" }
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
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
            if let size = lazyFileSize ?? item.formattedFileSize {
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

    private func loadMedia() {
        guard let asset = item.asset else { return }
        if isVideo {
            loadVideo(asset: asset)
        } else {
            loadImage(asset: asset)
        }
    }

    private func loadVideo(asset: PHAsset) {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat

        videoRequestID = PHImageManager.default().requestPlayerItem(
            forVideo: asset,
            options: options
        ) { playerItem, info in
            guard let playerItem else { return }
            DispatchQueue.main.async {
                let player = AVPlayer(playerItem: playerItem)
                self.player = player
                self.addTimeObserver(to: player)
                let isInCloud = info?[PHImageResultIsInCloudKey] as? Bool ?? false
                onCloudStatusUpdate?(isInCloud ? .iCloudOnly : .local)
            }
        }

        loadFileSize(asset: asset)
    }

    private func loadImage(asset: PHAsset) {
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

        loadFileSize(asset: asset)
    }

    private func loadFileSize(asset: PHAsset) {
        guard item.fileSize == nil else { return }
        DispatchQueue.global(qos: .utility).async { [asset] in
            if let size = PhotoLibraryService.fileSize(from: asset) {
                let formatted: String
                if size >= 1_000_000 {
                    formatted = String(format: "%.1f MB", Double(size) / 1_000_000)
                } else {
                    formatted = String(format: "%.0f KB", Double(size) / 1_000)
                }
                DispatchQueue.main.async { self.lazyFileSize = formatted }
            }
        }
    }

    // MARK: - Playback

    private func togglePlayback() {
        guard let player else { return }
        if isPlaying {
            player.pause()
        } else {
            player.play()
            scheduleAutoHide()
        }
        isPlaying.toggle()
    }

    // MARK: - Cleanup

    private func cancelRequest() {
        if let id = imageRequestID {
            PHImageManager.default().cancelImageRequest(id)
            imageRequestID = nil
        }
        if let id = videoRequestID {
            PHImageManager.default().cancelImageRequest(id)
            videoRequestID = nil
        }
        if let timeObserver, let player {
            player.removeTimeObserver(timeObserver)
        }
        timeObserver = nil
        player?.pause()
        player = nil
        isPlaying = false
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

// MARK: - Full screen video

private struct FullScreenVideoView: View {
    let player: AVPlayer?
    @State var isPlaying: Bool
    var onDismiss: (Bool) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                ProgressView().tint(.white)
            }

            Button(action: {
                onDismiss(isPlaying)
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.2), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(.top, 56)
            .padding(.trailing, 20)
        }
        .onAppear {
            player?.play()
            isPlaying = true
        }
    }
}

// MARK: - AVPlayerLayer-backed video view

private final class PlayerLayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}

private struct PlayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerLayerView {
        let view = PlayerLayerView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspect
        return view
    }

    func updateUIView(_ view: PlayerLayerView, context: Context) {
        view.playerLayer.player = player
    }
}

#Preview("Photo") {
    MediaCardView(item: MediaItem.mockItems[1])
        .frame(height: 480)
        .padding()
        .background(.black)
}

#Preview("Video") {
    MediaCardView(item: MediaItem.mockItems[0])
        .frame(height: 480)
        .padding()
        .background(.black)
}
