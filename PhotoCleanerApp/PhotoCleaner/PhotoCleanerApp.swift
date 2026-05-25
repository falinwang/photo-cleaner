import SwiftUI

@main
struct PhotoCleanerApp: App {
    @State private var appState = AppState()
    @State private var assetStore = AssetStore()
    @State private var library = PhotoLibraryService()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(appState)
                .environment(assetStore)
                .environment(library)
                .preferredColorScheme(.dark)
        }
    }
}
