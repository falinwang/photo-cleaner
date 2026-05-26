import SwiftUI

struct ReviewView: View {
    let mode: AppMode
    @State var session: ReviewSession
    @Environment(AssetStore.self) private var assetStore
    @Environment(\.dismiss) private var dismiss
    @State private var showHelp = false
    @State private var showAlbumStrip = false
    @State private var showSourcePanel = false

    // MARK: - Navigation swipe
    @State private var navDragOffset: CGFloat = 0
    @State private var favoriteDragOffset: CGFloat = 0
    @State private var showFavoriteOverlay = false
    private let navThreshold: CGFloat = 80
    private let favoriteThreshold: CGFloat = 120

    var body: some View {
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
            GeometryReader { geo in
                let sourceH: CGFloat = showSourcePanel ? 260 : 0
                let cardH = geo.size.height - topBarHeight - actionBarHeight - toggleRowHeight - sourceH

                VStack(spacing: 0) {
                    TopBarView(
                        mode: mode,
                        item: session.currentItem,
                        progressText: session.progressText,
                        trashHighlighted: false,
                        onClose: { dismiss() },
                        onHelp: { showHelp = true },
                        onTrash: { session.delete(store: assetStore) }
                    )

                    if let item = session.currentItem {
                        MediaCardView(item: item) { newStatus in
                            session.updateCloudStatus(newStatus, for: item.id)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .frame(width: geo.size.width, height: cardH)
                        .offset(x: navDragOffset, y: favoriteDragOffset)
                        .overlay {
                            if favoriteDragOffset > 0 || showFavoriteOverlay {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 72))
                                    .foregroundStyle(.red)
                                    .scaleEffect(showFavoriteOverlay ? 1.1 : min(1.0, favoriteDragOffset / favoriteThreshold))
                                    .opacity(showFavoriteOverlay ? 0.8 : favoriteDragOffset / favoriteThreshold)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showFavoriteOverlay)
                            }
                        }
                        .gesture(navGesture)
                        .id(item.id)
                    }

                    if showSourcePanel, let item = session.currentItem {
                        SourcePanelView(item: item)
                            .id(item.id)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    toggleRow

                    ActionBarView(
                        mode: mode,
                        undoCount: session.undoCount,
                        onSkip:   { session.skip() },
                        onKeep:   { session.keep(store: assetStore) },
                        onReturn: { session.returnToUnsorted(store: assetStore) },
                        onDelete: { session.delete(store: assetStore) },
                        onUndo:   { session.undo(store: assetStore) }
                    )

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
                    }
                }
            }
        }
    }

    private let topBarHeight: CGFloat = 72
    private let actionBarHeight: CGFloat = 110
    private let toggleRowHeight: CGFloat = 36

    // MARK: - Toggle row

    private var toggleRow: some View {
        HStack(spacing: 24) {
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { showSourcePanel.toggle() } }) {
                HStack(spacing: 4) {
                    Image(systemName: showSourcePanel ? "chevron.down" : "info.circle")
                    Text(showSourcePanel ? "HIDE DETAILS" : "SOURCE")
                        .kerning(0.5)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(showSourcePanel ? .white : .white.opacity(0.5))
            }

            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) { showAlbumStrip = true }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "square.grid.2x2")
                    Text("SORT TO ALBUM")
                        .kerning(0.5)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: - Gesture (horizontal nav + vertical-down favorite)

    private var navGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                if isHorizontal {
                    navDragOffset = value.translation.width
                    favoriteDragOffset = 0
                } else {
                    navDragOffset = 0
                    favoriteDragOffset = max(0, value.translation.height)
                }
            }
            .onEnded { value in
                let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                if isHorizontal {
                    if value.translation.width < -navThreshold {
                        let w = UIScreen.main.bounds.width
                        withAnimation(.easeOut(duration: 0.2)) { navDragOffset = -w }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                            navDragOffset = 0
                            session.moveToNext()
                        }
                    } else if value.translation.width > navThreshold {
                        let w = UIScreen.main.bounds.width
                        withAnimation(.easeOut(duration: 0.2)) { navDragOffset = w }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                            navDragOffset = 0
                            session.moveToPrevious()
                        }
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { navDragOffset = 0 }
                    }
                } else if value.translation.height > favoriteThreshold {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { favoriteDragOffset = 0 }
                    showFavoriteOverlay = true
                    session.favorite()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        showFavoriteOverlay = false
                    }
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        navDragOffset = 0
                        favoriteDragOffset = 0
                    }
                }
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
        case .largestFirst: return "arrow.up.arrow.down"
        }
    }

    private var emptyTitle: String {
        switch mode {
        case .onThisDay:    return "No memories for today"
        case .random:       return "Nothing left to review"
        case .unsorted:     return "All caught up!"
        case .keptForLater: return "Nothing kept for later"
        case .largestFirst: return "All clear!"
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
        case .largestFirst: return "No large files left to recover."
        }
    }
}

// MARK: - Help Sheet

private struct HelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let items: [(String, String, String)] = [
        ("arrow.left.and.right",  "Swipe",      "Navigate between items"),
        ("arrow.down.circle",     "Keep",       "Save to Kept for Later"),
        ("tray.and.arrow.up",    "Return",     "Send back to Unsorted"),
        ("forward",              "Skip",       "Skip to next item"),
        ("trash",                "Delete",     "Move to Trash"),
        ("square.grid.2x2",     "Sort",       "Sort to an album"),
        ("info.circle",          "Source",     "View version & metadata"),
        ("arrow.uturn.backward", "Undo",       "Revert the last action"),
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
            .navigationTitle("Actions")
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
