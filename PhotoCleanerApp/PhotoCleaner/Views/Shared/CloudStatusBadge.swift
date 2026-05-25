import SwiftUI

struct CloudStatusBadge: View {
    let status: CloudStatus

    private var color: Color {
        switch status {
        case .local:       return .green
        case .iCloudOnly:  return .cyan
        case .downloading: return .yellow
        case .failed:      return .red
        }
    }

    var body: some View {
        Label(status.rawValue, systemImage: status.icon)
            .font(.caption.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 0.5))
    }
}

#Preview {
    VStack {
        CloudStatusBadge(status: .local)
        CloudStatusBadge(status: .iCloudOnly)
        CloudStatusBadge(status: .downloading)
        CloudStatusBadge(status: .failed)
    }
    .padding()
    .background(.black)
}
