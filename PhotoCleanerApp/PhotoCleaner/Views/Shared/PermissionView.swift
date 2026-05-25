import SwiftUI

struct PermissionView: View {
    let onRequest: () async -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 64))
                    .foregroundStyle(.white.opacity(0.8))

                VStack(spacing: 8) {
                    Text("Photo Access Required")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("Photo Cleaner needs access to your library to help you organize photos and videos.")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    Task { await onRequest() }
                } label: {
                    Text("Allow Access")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white, in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 40)

                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.gray)
            }
            .padding()
        }
    }
}
