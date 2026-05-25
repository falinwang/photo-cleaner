import SwiftUI

struct ReviewView: View {
    let mode: AppMode
    @State var session: ReviewSession
    @Environment(AssetStore.self) private var assetStore
    @Environment(\.dismiss) private var dismiss
    @State private var showHelp = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if session.isEmpty {
                EmptyStateView(mode: mode, onBack: { dismiss() })
            } else {
                VStack(spacing: 0) {
                    TopBarView(
                        mode: mode,
                        item: session.currentItem,
                        progressText: session.progressText,
                        onClose: { dismiss() },
                        onTrash: { session.delete(store: assetStore) }
                    )

                    if let item = session.currentItem {
                        MediaCardView(item: item) { newStatus in
                            session.updateCloudStatus(newStatus, for: item.id)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: UIScreen.main.bounds.height * 0.53)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }

                    Spacer(minLength: 0)

                    ActionBarView(
                        canUndo: session.canUndo,
                        onSkip:     { session.skip() },
                        onKeep:     { session.keep(store: assetStore) },
                        onDelete:   { session.delete(store: assetStore) },
                        onFavorite: { session.favorite() },
                        onUndo:     { session.undo(store: assetStore) },
                        onHelp:     { showHelp = true }
                    )

                    AlbumStripView(
                        albums: MockAlbum.mockAlbums,
                        onSelect: { album in session.sortToAlbum(albumID: album.id, store: assetStore) },
                        onSeeAll: {}
                    )
                }
                .frame(maxWidth: .infinity)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showHelp) { HelpSheet() }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let mode: AppMode
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
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
        case .largestFirst: return "checkmark.seal"
        case .unsorted:     return "checkmark.circle"
        case .keptForLater: return "bookmark.slash"
        }
    }

    private var emptyTitle: String {
        switch mode {
        case .onThisDay:    return "No memories for today"
        case .random:       return "Nothing left to review"
        case .largestFirst: return "No large files found"
        case .unsorted:     return "All caught up!"
        case .keptForLater: return "Nothing kept for later"
        }
    }

    private var emptyMessage: String {
        switch mode {
        case .onThisDay:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d"
            let dateStr = formatter.string(from: Date())
            return "No photos or videos found for \(dateStr) in past years."
        case .random:
            return "All photos in your library have been organized."
        case .largestFirst:
            return "No large unsorted files in your library."
        case .unsorted:
            return "Every photo has been sorted, kept, or deleted."
        case .keptForLater:
            return "Photos you keep will appear here for review later."
        }
    }
}

// MARK: - Help Sheet

private struct HelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let items: [(String, String, String)] = [
        ("forward",              "Skip",     "Defer — item stays in queue"),
        ("arrow.down.circle",   "Keep",     "Move to Kept for Later"),
        ("xmark.circle",        "Delete",   "Move to in-app Trash"),
        ("square.grid.2x2",    "Sort",     "Tap an album chip below the card"),
        ("star",                "Favorite", "Mark as iOS Favorite"),
        ("arrow.uturn.backward","Undo",     "Revert the last action"),
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
            .navigationTitle("How it works")
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

#Preview("Empty — On This Day") {
    EmptyStateView(mode: .onThisDay, onBack: {})
}
