import SwiftUI
import SwiftData
import AVFoundation

@main
struct WavloApp: App {

    let modelContainer: ModelContainer
    @StateObject private var themeManager = ThemeManager()

    init() {
        let schema = Schema([
            Song.self,
            Playlist.self,
            ListeningHistory.self,
            UserPreferences.self
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Schema changed (e.g. new Song fields); remove incompatible store and retry
            Self.removeIncompatibleStore()
            do {
                modelContainer = try ModelContainer(for: schema, configurations: [config])
            } catch {
                // Fallback: in-memory so the app still launches
                print("Wavlo: Could not load persistent store, using in-memory. \(error)")
                let inMemoryConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true
                )
                modelContainer = try! ModelContainer(for: schema, configurations: [inMemoryConfig])
            }
        }
        configureAudioSession()
    }

    private static func removeIncompatibleStore() {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        let bundleId = Bundle.main.bundleIdentifier ?? "com.wavlo"
        let subdir = appSupport.appendingPathComponent(bundleId)
        let defaultStore = appSupport.appendingPathComponent("default.store")
        let namedStore = subdir.appendingPathComponent("default.store")
        try? FileManager.default.removeItem(at: defaultStore)
        try? FileManager.default.removeItem(at: namedStore)
        try? FileManager.default.removeItem(atPath: subdir.path)
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            // Use no options first to avoid NSOSStatusErrorDomain -50 on simulator/some devices
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            print("Wavlo: Audio session configuration failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(PlayerViewModel.shared)
                .environmentObject(themeManager)
        }
        .modelContainer(modelContainer)
    }
}
