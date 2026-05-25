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
                emptyState
            } else {
                VStack(spacing: 0) {
                    TopBarView(
                        mode: mode,
                        item: session.currentItem,
                        progressText: session.progressText,
                        onClose: { dismiss() },
                        onTrash: { session.delete(store: assetStore) }
                    )

                    Spacer(minLength: 12)

                    if let item = session.currentItem {
                        MediaCardView(item: item) { newStatus in
                            session.updateCloudStatus(newStatus, for: item.id)
                        }
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 12)

                    ActionBarView(
                        canUndo: session.canUndo,
                        onSkip:    { session.skip() },
                        onKeep:    { session.keep(store: assetStore) },
                        onDelete:  { session.delete(store: assetStore) },
                        onFavorite: { session.favorite() },
                        onUndo:    { session.undo(store: assetStore) },
                        onHelp:    { showHelp = true }
                    )

                    AlbumStripView(
                        albums: MockAlbum.mockAlbums,
                        onSelect: { album in
                            session.sortToAlbum(albumID: album.id, store: assetStore)
                        },
                        onSeeAll: { /* AlbumPickerView in M2 */ }
                    )
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showHelp) { HelpSheet() }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 56))
                .foregroundStyle(.green)
            Text("All done!")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("Nothing left to review in \(mode.rawValue).")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
            Button("Go back") { dismiss() }
                .foregroundStyle(.blue)
        }
        .padding()
    }
}

// MARK: - Help Sheet

private struct HelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let gestures: [(String, String, String)] = [
        ("forward", "Skip",         "Defer — item stays in queue"),
        ("arrow.down.circle", "Keep", "Move to Kept for Later"),
        ("xmark.circle", "Delete",  "Move to in-app Trash"),
        ("square.grid.2x2", "Sort", "Tap an album chip below"),
        ("star", "Favorite",        "Mark as iOS Favorite"),
        ("arrow.uturn.backward", "Undo", "Revert the last action"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                List(gestures, id: \.0) { icon, title, detail in
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
