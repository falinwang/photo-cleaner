import SwiftUI

struct ReviewView: View {
    let mode: AppMode
    @State var session: ReviewSession
    @Environment(AssetStore.self) private var assetStore
    @Environment(\.dismiss) private var dismiss
    @State private var showHelp = false
    @State private var showAlbumStrip = false

    // MARK: - Gesture state
    @State private var dragOffset: CGSize = .zero
    private let swipeThreshold: CGFloat = 90

    var body: some View {
        // Use VStack + .background instead of ZStack — avoids width-constraint issues
        // that appear when a VStack is a child of ZStack with ignoresSafeArea content.
        contentView
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showHelp) { HelpSheet() }
    }

    @ViewBuilder
    private var contentView: some View {
        if session.isEmpty {
            EmptyStateView(mode: mode, onBack: { dismiss() })
        } else {
            VStack(spacing: 0) {
                TopBarView(
                    mode: mode,
                    item: session.currentItem,
                    progressText: session.progressText,
                    trashHighlighted: isDraggingToDelete,
                    onClose: { dismiss() },
                    onHelp: { showHelp = true },
                    onTrash: { animateAndCommit(.delete) }
                )

                if let item = session.currentItem {
                    cardLayer(for: item)
                }

                Spacer(minLength: 0)

                ActionBarView(
                    mode: mode,
                    undoCount: session.undoCount,
                    onSkip:   { animateAndCommit(.skip) },
                    onKeep:   { animateAndCommit(.keep) },
                    onReturn: { animateAndCommit(.keep) },
                    onDelete: { animateAndCommit(.delete) },
                    onUndo:   { session.undo(store: assetStore) }
                )

                // Sort-to-album strip — collapsed by default to keep the card prominent
                if showAlbumStrip {
                    AlbumStripView(
                        albums: MockAlbum.mockAlbums,
                        onSelect: { album in
                            session.sortToAlbum(albumID: album.id, store: assetStore)
                            withAnimation(.easeInOut(duration: 0.2)) { showAlbumStrip = false }
                        },
                        onDismiss: {
                            withAnimation(.easeInOut(duration: 0.2)) { showAlbumStrip = false }
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) { showAlbumStrip = true }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.grid.2x2")
                            Text("SORT TO ALBUM")
                                .kerning(0.5)
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.vertical, 10)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private func cardLayer(for item: MediaItem) -> some View {
        MediaCardView(item: item) { newStatus in
            session.updateCloudStatus(newStatus, for: item.id)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offset(dragOffset)
        .rotationEffect(.degrees(Double(dragOffset.width / 22)), anchor: .bottom)
        .overlay(swipeOverlay(for: item))
        .gesture(cardDragGesture)
        .id(item.id)
    }

    // MARK: - Swipe direction

    private enum SwipeAction {
        case skip       // swipe left
        case keep       // swipe right
        case delete     // swipe up
        case favorite   // swipe down

        var label: String {
            switch self {
            case .skip:     return "SKIP"
            case .delete:   return "DELETE"
            case .keep:     return "KEEP"
            case .favorite: return "FAVORITE"
            }
        }
        var icon: String {
            switch self {
            case .skip:     return "forward.fill"
            case .delete:   return "trash.fill"
            case .keep:     return "arrow.down.circle.fill"
            case .favorite: return "star.fill"
            }
        }
        var color: Color {
            switch self {
            case .skip:     return .gray
            case .delete:   return .red
            case .keep:     return .blue
            case .favorite: return .yellow
            }
        }
        var exitOffset: CGSize {
            switch self {
            case .skip:     return CGSize(width: -700, height: -30)
            case .delete:   return CGSize(width: 0,    height: -700)
            case .keep:     return CGSize(width: 700,  height: -30)
            case .favorite: return CGSize(width: 0,    height: 900)
            }
        }
    }

    // Simple 1D axes: left=skip, right=keep, up=delete, down=favorite
    private var pendingAction: SwipeAction? {
        let x = dragOffset.width
        let y = dragOffset.height
        let t = swipeThreshold

        if x < -t && abs(x) > abs(y) { return .skip }
        if x > t && abs(x) > abs(y) { return .keep }
        if y < -t && abs(y) > abs(x) { return .delete }
        if y > t && abs(y) > abs(x) { return .favorite }
        return nil
    }

    private var dragProgress: CGFloat {
        let x = abs(dragOffset.width)
        let y = abs(dragOffset.height)
        return min(max(x, y) / swipeThreshold, 1.0)
    }

    // True while the card is being dragged toward the trash icon
    var isDraggingToDelete: Bool { pendingAction == .delete }

    // MARK: - Gesture

    private var cardDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { _ in
                if let action = pendingAction {
                    animateAndCommit(action)
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        dragOffset = .zero
                    }
                }
            }
    }

    private func animateAndCommit(_ action: SwipeAction) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        withAnimation(.easeOut(duration: 0.25)) {
            dragOffset = action.exitOffset
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            dragOffset = .zero
            switch action {
            case .skip:     session.skip()
            case .keep:     if mode == .keptForLater { session.returnToUnsorted(store: assetStore) }
                            else { session.keep(store: assetStore) }
            case .delete:   session.delete(store: assetStore)
            case .favorite: session.favorite()
            }
        }
    }

    // MARK: - Overlay

    @ViewBuilder
    private func swipeOverlay(for item: MediaItem) -> some View {
        if let action = pendingAction {
            let label: String = {
                if action == .keep && mode == .keptForLater { return "RETURN" }
                return action.label
            }()
            let icon: String = {
                if action == .keep && mode == .keptForLater { return "tray.and.arrow.up.fill" }
                return action.icon
            }()
            RoundedRectangle(cornerRadius: 16)
                .fill(action.color.opacity(0.25 * dragProgress))
                .overlay(
                    VStack(spacing: 6) {
                        Image(systemName: icon)
                            .font(.system(size: 44, weight: .bold))
                        Text(label)
                            .font(.title2.bold())
                            .kerning(1)
                    }
                    .foregroundStyle(action.color)
                    .opacity(Double(dragProgress))
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let mode: AppMode
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.white.opacity(0.1), in: Circle())
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 4)

            Spacer()

            VStack(spacing: 20) {
                Image(systemName: emptyIcon)
                    .font(.system(size: 64))
                    .foregroundStyle(.white.opacity(0.25))

                VStack(spacing: 8) {
                    Text(emptyTitle)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text(emptyMessage)
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Button(action: onBack) {
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

    private var emptyIcon: String {
        switch mode {
        case .onThisDay:    return "calendar.badge.exclamationmark"
        case .random:       return "shuffle"
case .unsorted:     return "checkmark.circle"
        case .keptForLater: return "bookmark.slash"
        }
    }

    private var emptyTitle: String {
        switch mode {
        case .onThisDay:    return "No memories for today"
        case .random:       return "Nothing left to review"
case .unsorted:     return "All caught up!"
        case .keptForLater: return "Nothing kept for later"
        }
    }

    private var emptyMessage: String {
        switch mode {
        case .onThisDay:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d"
            return "No photos or videos found for \(formatter.string(from: Date())) in past years."
        case .random:       return "All photos in your library have been organized."
case .unsorted:     return "Every photo has been sorted, kept, or deleted."
        case .keptForLater: return "Tap KEEP on any photo to save it here. Tap RETURN to send it back to Unsorted."
        }
    }
}

// MARK: - Help Sheet

private struct HelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let items: [(String, String, String)] = [
        ("arrow.left",           "Swipe left",  "Skip"),
        ("arrow.right",          "Swipe right", "Keep for Later"),
        ("arrow.up",             "Swipe up",    "Delete to Trash"),
        ("arrow.down",           "Swipe down",  "Favorite"),
        ("square.grid.2x2",     "Album strip", "Tap a chip to sort"),
        ("arrow.uturn.backward", "Undo",        "Revert the last action"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                List(items, id: \.0) { icon, title, detail in
                    HStack(spacing: 14) {
                        Image(systemName: icon)
                            .frame(width: 28)
                            .foregroundStyle(.white)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title).foregroundStyle(.white).font(.headline)
                            Text(detail).foregroundStyle(.gray).font(.caption)
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.07))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Gestures")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    ReviewView(
        mode: .unsorted,
        session: ReviewSession(items: MediaItem.mockItems)
    )
    .environment(AssetStore())
}

#Preview("Empty") {
    EmptyStateView(mode: .onThisDay, onBack: {})
}
