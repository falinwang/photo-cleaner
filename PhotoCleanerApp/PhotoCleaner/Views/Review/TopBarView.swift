import SwiftUI

struct TopBarView: View {
    let mode: AppMode
    let item: MediaItem?
    let progressText: String
    var trashHighlighted: Bool = false
    let onClose: () -> Void
    let onHelp: () -> Void
    let onTrash: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.white.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)

                Spacer(minLength: 8)

                Text(mode.rawValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 8)

                Button(action: onHelp) {
                    Image(systemName: "questionmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.white.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)

                // Trash icon — glows red and scales up when card is dragged toward it
                Button(action: onTrash) {
                    Image(systemName: trashHighlighted ? "trash.fill" : "trash")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(trashHighlighted ? .red : .white)
                        .frame(width: 36, height: 36)
                        .background(
                            trashHighlighted ? .red.opacity(0.2) : .white.opacity(0.12),
                            in: Circle()
                        )
                        .scaleEffect(trashHighlighted ? 1.25 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: trashHighlighted)
                }
                .buttonStyle(.plain)
            }

            if let item {
                HStack(spacing: 6) {
                    Text(progressText)
                        .foregroundStyle(.white.opacity(0.85))
                    Text("·")
                        .foregroundStyle(.gray)
                    Text(Self.compactDate(item.creationDate))
                        .foregroundStyle(.gray)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: 0)
                }
                .font(.caption)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private static let compactFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    private static func compactDate(_ date: Date?) -> String {
        guard let date else { return "Unknown" }
        return compactFormatter.string(from: date)
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
            onHelp: {},
            onTrash: {}
        )
        TopBarView(
            mode: .unsorted,
            item: MediaItem.mockItems[0],
            progressText: "1/213",
            trashHighlighted: true,
            onClose: {},
            onHelp: {},
            onTrash: {}
        )
    }
    .background(.black)
}
