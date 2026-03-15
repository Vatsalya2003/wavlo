import SwiftUI
import SwiftData

struct AccountView: View {

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var theme: ThemeManager
    @Query private var prefs: [UserPreferences]
    @State private var displayName: String = ""

    private var userPrefs: UserPreferences? { prefs.first }
    private var colors: WavloColors { theme.colors }

    var body: some View {
        Form {
            Section {
                TextField("Display name", text: $displayName)
                    .foregroundStyle(colors.textPrimary)
                HStack {
                    Text("Email")
                    Spacer()
                    Text("Local Account")
                        .foregroundStyle(colors.textMuted)
                }
            } header: {
                Text("Profile")
            }

            Section {
                HStack {
                    Text("Storage used")
                    Spacer()
                    Text("Cached on device")
                        .foregroundStyle(colors.textMuted)
                }
                Button("Clear cache") {
                    // Stub: clear cached data if any
                }
                .foregroundStyle(colors.primaryAccent)
            } header: {
                Text("Storage")
            }
        }
        .scrollContentBackground(.hidden)
        .background(colors.bgPrimary)
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            displayName = userPrefs?.displayName ?? "Wavlo User"
        }
        .onDisappear {
            savePrefs()
        }
    }

    private func savePrefs() {
        let prefsToUse: UserPreferences
        if let existing = prefs.first {
            prefsToUse = existing
        } else {
            let newPrefs = UserPreferences()
            modelContext.insert(newPrefs)
            prefsToUse = newPrefs
        }
        prefsToUse.displayName = displayName.isEmpty ? nil : displayName
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        AccountView()
            .environmentObject(ThemeManager())
            .modelContainer(for: [UserPreferences.self], inMemory: true)
    }
}
