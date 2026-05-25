import SwiftUI

struct MediaTypeBadge: View {
    let mediaType: MediaType

    private var color: Color {
        switch mediaType {
        case .photo:      return .blue
        case .video:      return .purple
        case .screenshot: return .orange
        case .other:      return .gray
        }
    }

    var body: some View {
        Label(mediaType.rawValue, systemImage: mediaType.icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2), in: Capsule())
    }
}

#Preview {
    HStack {
        MediaTypeBadge(mediaType: .photo)
        MediaTypeBadge(mediaType: .video)
        MediaTypeBadge(mediaType: .screenshot)
        MediaTypeBadge(mediaType: .other)
    }
    .padding()
    .background(.black)
}
