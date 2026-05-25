import SwiftUI

struct TopBarView: View {
    let mode: AppMode
    let item: MediaItem?
    let progressText: String
    var trashHighlighted: Bool = false
    let onClose: () -> Void
    let onTrash: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.white.opacity(0.1), in: Circle())
                }

                Spacer()

                Text(mode.rawValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Spacer()

                // Trash icon — glows red and scales up when card is dragged toward it
                Button(action: onTrash) {
                    Image(systemName: trashHighlighted ? "trash.fill" : "trash")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(trashHighlighted ? .red : .white)
                        .frame(width: 36, height: 36)
                        .background(
                            trashHighlighted ? .red.opacity(0.2) : .white.opacity(0.1),
                            in: Circle()
                        )
                        .scaleEffect(trashHighlighted ? 1.25 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: trashHighlighted)
                }
            }

            if let item {
                HStack(spacing: 8) {
                    Image(systemName: "star")
                        .foregroundStyle(.yellow.opacity(0.7))
                    Text(progressText)
                        .foregroundStyle(.white.opacity(0.8))
                    Text("·")
                        .foregroundStyle(.gray)
                    Text(item.formattedDate)
                        .foregroundStyle(.gray)
                    Spacer()
                }
                .font(.caption)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .padding(.top, 4)
    }
}

#Preview {
    VStack(spacing: 20) {
        TopBarView(
            mode: .unsorted,
            item: MediaItem.mockItems[0],
            progressText: "1/213",
            trashHighlighted: false,
            onClose: {},
            onTrash: {}
        )
        TopBarView(
            mode: .unsorted,
            item: MediaItem.mockItems[0],
            progressText: "1/213",
            trashHighlighted: true,
            onClose: {},
            onTrash: {}
        )
    }
    .background(.black)
}
