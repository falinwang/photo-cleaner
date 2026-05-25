import SwiftUI
import Photos

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(AssetStore.self) private var assetStore
    @Environment(PhotoLibraryService.self) private var library
    @State private var destination: AppMode? = nil
    @State private var showTrash = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                content
            }
            .toolbar(.hidden, for: .navigationBar)
            // Compute session directly in the destination closure — avoids nil timing bug
            .navigationDestination(item: $destination) { mode in
                ReviewView(
                    mode: mode,
                    session: ReviewSession(items: library.fetchItems(for: mode, store: assetStore))
                )
            }
            .sheet(isPresented: $showTrash) {
                TrashView()
                    .environment(assetStore)
            }
        }
        .task {
            if library.authorizationStatus == .notDetermined {
                await library.requestAuthorization()
            }
        }
    }

    // MARK: - Content branch

    @ViewBuilder
    private var content: some View {
        switch library.authorizationStatus {
        case .authorized, .limited:
            modeList
        case .denied, .restricted:
            PermissionView { await library.requestAuthorization() }
        default:
            PermissionView { await library.requestAuthorization() }
        }
    }

    // MARK: - Mode list

    private var modeList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                VStack(spacing: 12) {
                    ForEach(AppMode.allCases) { mode in
                        ModeCard(mode: mode) { destination = mode }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Photo Cleaner")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Text(Date.now.formatted(date: .complete, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            Spacer()
            Button(action: { showTrash = true }) {
                ZStack {
                    Image(systemName: "trash")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(assetStore.trashedIDs.isEmpty ? .white.opacity(0.5) : .red)
                    if !assetStore.trashedIDs.isEmpty {
                        Text("\(min(assetStore.trashedIDs.count, 99))")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(3)
                            .background(.red, in: Circle())
                            .offset(x: 8, y: -8)
                    }
                }
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(.horizontal)
        .padding(.top, 56)
        .padding(.bottom, 24)
    }
}

// MARK: - ModeCard

private struct ModeCard: View {
    let mode: AppMode
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: mode.icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.rawValue)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(mode.description)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.gray)
            }
            .padding()
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
        .environment(AppState())
        .environment(AssetStore())
        .environment(PhotoLibraryService())
}
