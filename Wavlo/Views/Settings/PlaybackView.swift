import SwiftUI
import SwiftData

struct PlaybackView: View {

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var theme: ThemeManager
    @Query private var prefs: [UserPreferences]

    private var userPrefs: UserPreferences? { prefs.first }
    private var colors: WavloColors { theme.colors }

    var body: some View {
        Form {
            Section {
                Toggle("Crossfade", isOn: binding(\.playbackCrossfade))
                    .tint(colors.primaryAccent)
                Toggle("Gapless playback", isOn: binding(\.playbackGapless))
                    .tint(colors.primaryAccent)
                Toggle("Auto-play similar songs", isOn: binding(\.autoPlaySimilar))
                    .tint(colors.primaryAccent)
            } header: {
                Text("Playback")
            }
        }
        .scrollContentBackground(.hidden)
        .background(colors.bgPrimary)
        .navigationTitle("Playback")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            try? modelContext.save()
        }
    }

    private func binding(_ keyPath: WritableKeyPath<UserPreferences, Bool>) -> Binding<Bool> {
        Binding(
            get: { userPrefs?[keyPath: keyPath] ?? (keyPath == \.playbackGapless ? true : false) },
            set: { newValue in
                var prefsToUse: UserPreferences
                if let existing = prefs.first {
                    prefsToUse = existing
                } else {
                    let newPrefs = UserPreferences()
                    modelContext.insert(newPrefs)
                    prefsToUse = newPrefs
                }
                prefsToUse[keyPath: keyPath] = newValue
            }
        )
    }
}

#Preview {
    NavigationStack {
        PlaybackView()
            .environmentObject(ThemeManager())
            .modelContainer(for: [UserPreferences.self], inMemory: true)
    }
}
