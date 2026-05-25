import SwiftUI

struct ActionBarView: View {
    let canUndo: Bool
    let onSkip: () -> Void
    let onKeep: () -> Void
    let onDelete: () -> Void
    let onFavorite: () -> Void
    let onUndo: () -> Void
    let onHelp: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Undo + Favorite strip
            HStack {
                Button(action: onUndo) {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(canUndo ? .white : .gray)
                }
                .disabled(!canUndo)

                Spacer()

                Button(action: onFavorite) {
                    Label("Favorite", systemImage: "star")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.yellow)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            Divider().background(.white.opacity(0.1))

            // Main action row
            HStack(spacing: 0) {
                ActionButton(
                    label: "HELP",
                    icon: "questionmark.circle",
                    color: .gray,
                    action: onHelp
                )

                Divider()
                    .frame(height: 36)
                    .background(.white.opacity(0.15))

                ActionButton(
                    label: "SKIP",
                    icon: "forward",
                    color: .white,
                    action: onSkip
                )

                Divider()
                    .frame(height: 36)
                    .background(.white.opacity(0.15))

                ActionButton(
                    label: "KEEP",
                    icon: "arrow.down.circle",
                    color: .white,
                    action: onKeep
                )

                Divider()
                    .frame(height: 36)
                    .background(.white.opacity(0.15))

                ActionButton(
                    label: "DELETE",
                    icon: "xmark",
                    color: .red,
                    action: onDelete
                )
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 12)
        .background(.black)
    }
}

private struct ActionButton: View {
    let label: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.body)
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .kerning(0.3)
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ActionBarView(
        canUndo: true,
        onSkip: {},
        onKeep: {},
        onDelete: {},
        onFavorite: {},
        onUndo: {},
        onHelp: {}
    )
    .background(.black)
}
