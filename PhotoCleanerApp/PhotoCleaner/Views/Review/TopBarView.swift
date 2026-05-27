import SwiftUI

struct TopBarView: View {
    let mode: AppMode
    let item: MediaItem?
    let progressText: String
    var trashCount: Int = 0
    let onClose: () -> Void
    let onHelp: () -> Void
    let onTrashOpen: () -> Void

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

                // Trash icon — opens TrashView to review deleted items
                Button(action: onTrashOpen) {
                    ZStack {
                        Image(systemName: "trash")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(trashCount > 0 ? .red : .white.opacity(0.5))
                        if trashCount > 0 {
                            Text("\(min(trashCount, 99))")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(3)
                                .background(.red, in: Circle())
                                .offset(x: 8, y: -8)
                        }
                    }
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.12), in: Circle())
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
            trashCount: 0,
            onClose: {},
            onHelp: {},
            onTrashOpen: {}
        )
        TopBarView(
            mode: .unsorted,
            item: MediaItem.mockItems[0],
            progressText: "1/213",
            trashCount: 5,
            onClose: {},
            onHelp: {},
            onTrashOpen: {}
        )
    }
    .background(.black)
}
