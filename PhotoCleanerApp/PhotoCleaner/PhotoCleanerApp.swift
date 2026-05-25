import SwiftUI

@main
struct PhotoCleanerApp: App {
    @State private var appState = AppState()
    @State private var assetStore: AssetStore = {
        let store = AssetStore()
        // ⚠️ DEV ONE-TIME RESET — DELETE THESE 2 LINES AFTER NEXT LAUNCH
        store.reset()
        print("[DEV] AssetStore reset — all photos now Unsorted")
        return store
    }()
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
