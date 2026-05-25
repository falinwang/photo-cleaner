import SwiftUI

struct AlbumStripView: View {
    let albums: [MockAlbum]
    let onSelect: (MockAlbum) -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onDismiss) {
                HStack {
                    Image(systemName: "square.grid.2x2")
                    Text("SORT TO ALBUM")
                        .kerning(0.5)
                    Spacer()
                    Image(systemName: "chevron.down")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal)
                .padding(.vertical, 10)
            }

            Divider().background(.white.opacity(0.1))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(albums) { album in
                        AlbumChip(album: album) {
                            onSelect(album)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
        }
        .background(.black)
    }
}

private struct AlbumChip: View {
    let album: MockAlbum
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(album.emoji)
                    .font(.title2)
                    .frame(width: 52, height: 52)
                    .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                Text(album.name)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
                    .frame(width: 60)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AlbumStripView(
        albums: MockAlbum.mockAlbums,
        onSelect: { _ in },
        onDismiss: {}
    )
    .background(.black)
}
