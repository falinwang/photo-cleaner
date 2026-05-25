import SwiftUI

struct ActionBarView: View {
    let mode: AppMode
    let undoCount: Int
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
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.uturn.backward")
                        Text(undoCount > 1 ? "Undo (\(undoCount))" : "Undo")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(undoCount > 0 ? .white : .gray)
                }
                .disabled(undoCount == 0)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            Divider().background(.white.opacity(0.1))

            // Main action row — KEEP is the primary action
            HStack(spacing: 0) {
                ActionButton(
                    label: "SKIP",
                    icon: "forward",
                    color: .gray,
                    action: onSkip
                )

                if isKeptForLater {
                    PrimaryActionButton(
                        label: "RETURN",
                        icon: "tray.and.arrow.up",
                        action: onReturn
                    )
                } else {
                    PrimaryActionButton(
                        label: "KEEP",
                        icon: "arrow.down.circle",
                        action: onKeep
                    )
                }

                ActionButton(
                    label: "DELETE",
                    icon: "trash",
                    color: .red,
                    action: onDelete
                )
            }
            .padding(.vertical, 8)
        }
        .padding(.vertical, 8)
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
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}

private struct PrimaryActionButton: View {
    let label: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.body)
                Text(label)
                    .font(.caption2.weight(.bold))
                    .kerning(0.3)
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.white, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 8)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Unsorted") {
    ActionBarView(
        mode: .unsorted,
        undoCount: 3,
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
        undoCount: 1,
        onSkip: {},
        onKeep: {},
        onReturn: {},
        onDelete: {},
        onUndo: {}
    )
    .background(.black)
}
