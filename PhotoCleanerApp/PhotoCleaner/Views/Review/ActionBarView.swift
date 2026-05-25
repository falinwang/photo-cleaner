import SwiftUI

struct ActionBarView: View {
    let mode: AppMode
    let canUndo: Bool
    let onSkip: () -> Void
    let onKeep: () -> Void
    let onReturn: () -> Void
    let onDelete: () -> Void
    let onUndo: () -> Void

    private var isKeptForLater: Bool { mode == .keptForLater }

    var body: some View {
        VStack(spacing: 0) {
            // Undo strip
            HStack {
                Button(action: onUndo) {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(canUndo ? .white : .gray)
                }
                .disabled(!canUndo)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            Divider().background(.white.opacity(0.1))

            // Main action row — three equal actions
            HStack(spacing: 0) {
                ActionButton(
                    label: "SKIP",
                    icon: "forward",
                    color: .white,
                    action: onSkip
                )

                Divider()
                    .frame(height: 36)
                    .background(.white.opacity(0.15))

                if isKeptForLater {
                    ActionButton(
                        label: "RETURN",
                        icon: "tray.and.arrow.up",
                        color: .blue,
                        action: onReturn
                    )
                } else {
                    ActionButton(
                        label: "KEEP",
                        icon: "arrow.down.circle",
                        color: .white,
                        action: onKeep
                    )
                }

                Divider()
                    .frame(height: 36)
                    .background(.white.opacity(0.15))

                ActionButton(
                    label: "DELETE",
                    icon: "trash",
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

#Preview("Unsorted") {
    ActionBarView(
        mode: .unsorted,
        canUndo: true,
        onSkip: {},
        onKeep: {},
        onReturn: {},
        onDelete: {},
        onUndo: {}
    )
    .background(.black)
}

#Preview("Kept for Later") {
    ActionBarView(
        mode: .keptForLater,
        canUndo: true,
        onSkip: {},
        onKeep: {},
        onReturn: {},
        onDelete: {},
        onUndo: {}
    )
    .background(.black)
}
