import SwiftUI

struct TopBarView: View {
    let mode: AppMode
    let item: MediaItem?
    let progressText: String
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

                Button(action: onTrash) {
                    Image(systemName: "trash")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.white.opacity(0.1), in: Circle())
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
        .padding(.horizontal)
        .padding(.top, 4)
    }
}

#Preview {
    TopBarView(
        mode: .unsorted,
        item: MediaItem.mockItems[0],
        progressText: "1/213",
        onClose: {},
        onTrash: {}
    )
    .background(.black)
}
