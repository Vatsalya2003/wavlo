import SwiftUI
import SwiftData

struct SettingsView: View {

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var authVM: AuthViewModel
    @Query private var prefs: [UserPreferences]

    private var userPrefs: UserPreferences? { prefs.first }
    private var colors: WavloColors { theme.colors }

    var body: some View {
        List {
            profileSection
            Section {
                NavigationLink("Account") { AccountView() }
                NavigationLink("Data-saving and offline") { DataSavingPlaceholderView() }
                NavigationLink("Playback") { PlaybackView() }
                NavigationLink {
                    ContentDisplayView()
                } label: {
                    HStack {
                        Text("Content and display")
                        Spacer()
                    }
                }
                NavigationLink {
                    PrivacyView()
                } label: {
                    Text("Privacy and social")
                }
                NavigationLink {
                    MediaQualityView()
                } label: {
                    Text("Media quality")
                }
                NavigationLink("Notifications") { NotificationsPlaceholderView() }
                NavigationLink("Apps and devices") { AppsDevicesPlaceholderView() }
                NavigationLink("About") { AboutView() }
            }
            .listRowBackground(colors.bgCard)
            .foregroundStyle(colors.textPrimary)

            Section {
                Button("Log out") {
                    authVM.signOut()
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(colors.textPrimary)
            }
            .listRowBackground(colors.bgCard)

            Section {
                Text(appVersion)
                    .font(Constants.Typography.caption)
                    .foregroundStyle(colors.textMuted)
                    .frame(maxWidth: .infinity)
            }
            .listRowBackground(colors.bgPrimary)
        }
        .scrollContentBackground(.hidden)
        .background(colors.bgPrimary)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }

    private var profileSection: some View {
        Section {
            VStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(colors.textMuted)
                Text(authVM.displayName ?? userPrefs?.displayName ?? "Wavlo User")
                    .font(Constants.Typography.titleMedium)
                    .foregroundStyle(colors.textPrimary)
                if let email = authVM.email {
                    Text(email)
                        .font(Constants.Typography.bodySmall)
                        .foregroundStyle(colors.textSecondary)
                }
                Text("Signed in with \(authVM.providerName)")
                    .font(Constants.Typography.caption)
                    .foregroundStyle(colors.textMuted)
                Text("View Profile")
                    .font(Constants.Typography.bodySmall)
                    .foregroundStyle(colors.primaryAccent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .listRowBackground(colors.bgCard)
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        return "Wavlo v\(version)"
    }
}

// MARK: - Placeholder / inline sub-views

private struct DataSavingPlaceholderView: View {
    @EnvironmentObject private var theme: ThemeManager
    var body: some View {
        Text("Coming soon")
            .foregroundStyle(theme.colors.textMuted)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.colors.bgPrimary)
            .navigationTitle("Data-saving and offline")
    }
}

private struct NotificationsPlaceholderView: View {
    @EnvironmentObject private var theme: ThemeManager
    var body: some View {
        Text("Coming soon")
            .foregroundStyle(theme.colors.textMuted)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.colors.bgPrimary)
            .navigationTitle("Notifications")
    }
}

private struct AppsDevicesPlaceholderView: View {
    @EnvironmentObject private var theme: ThemeManager
    var body: some View {
        Text("Coming soon")
            .foregroundStyle(theme.colors.textMuted)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.colors.bgPrimary)
            .navigationTitle("Apps and devices")
    }
}

private struct ContentDisplayView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var theme: ThemeManager
    @Query private var prefs: [UserPreferences]
    private var userPrefs: UserPreferences? { prefs.first }
    private var colors: WavloColors { theme.colors }

    var body: some View {
        Form {
            Section("Theme") {
                Toggle("Dark mode", isOn: theme.isDarkModeBinding)
                    .tint(colors.primaryAccent)
            }
            Section("Language") {
                Picker("Music language", selection: languageBinding) {
                    Text("Hindi").tag("hindi")
                    Text("English").tag("english")
                    Text("Punjabi").tag("punjabi")
                    Text("Tamil").tag("tamil")
                }
                .foregroundStyle(colors.textPrimary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(colors.bgPrimary)
        .navigationTitle("Content and display")
        .onDisappear { try? modelContext.save() }
    }

    private var languageBinding: Binding<String> {
        Binding(
            get: { userPrefs?.preferredMusicLanguage ?? "english" },
            set: { newValue in
                let p = prefs.first ?? { let n = UserPreferences(); modelContext.insert(n); return n }()
                p.preferredMusicLanguage = newValue
            }
        )
    }
}

private struct PrivacyView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var theme: ThemeManager
    @Query private var prefs: [UserPreferences]
    private var userPrefs: UserPreferences? { prefs.first }
    private var colors: WavloColors { theme.colors }

    var body: some View {
        Form {
            Section {
                Toggle("Listening history", isOn: binding(\.listeningHistoryEnabled))
                    .tint(colors.primaryAccent)
                Button("Clear listening history") {
                    clearHistory()
                }
                .foregroundStyle(colors.primaryAccent)
                Toggle("Private session", isOn: binding(\.privateSession))
                    .tint(colors.primaryAccent)
            }
        }
        .scrollContentBackground(.hidden)
        .background(colors.bgPrimary)
        .navigationTitle("Privacy and social")
        .onDisappear { try? modelContext.save() }
    }

    private func binding(_ keyPath: WritableKeyPath<UserPreferences, Bool>) -> Binding<Bool> {
        Binding(
            get: { userPrefs?[keyPath: keyPath] ?? true },
            set: { newValue in
                var p = prefs.first ?? { let n = UserPreferences(); modelContext.insert(n); return n }()
                p[keyPath: keyPath] = newValue
            }
        )
    }

    private func clearHistory() {
        let descriptor = FetchDescriptor<ListeningHistory>()
        guard let list = try? modelContext.fetch(descriptor) else { return }
        for item in list { modelContext.delete(item) }
        try? modelContext.save()
    }
}

private struct MediaQualityView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var theme: ThemeManager
    @Query private var prefs: [UserPreferences]
    private var userPrefs: UserPreferences? { prefs.first }
    private var colors: WavloColors { theme.colors }

    var body: some View {
        Form {
            Section {
                Picker("Streaming quality", selection: qualityBinding) {
                    Text("Low (96 kbps)").tag("low")
                    Text("Normal (160 kbps)").tag("normal")
                    Text("High (320 kbps)").tag("high")
                }
                .foregroundStyle(colors.textPrimary)
            } footer: {
                Text("High quality uses more data")
            }
        }
        .scrollContentBackground(.hidden)
        .background(colors.bgPrimary)
        .navigationTitle("Media quality")
        .onDisappear { try? modelContext.save() }
    }

    private var qualityBinding: Binding<String> {
        Binding(
            get: { userPrefs?.streamingQuality ?? "normal" },
            set: { newValue in
                let p = prefs.first ?? { let n = UserPreferences(); modelContext.insert(n); return n }()
                p.streamingQuality = newValue
            }
        )
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(ThemeManager())
            .modelContainer(for: [UserPreferences.self], inMemory: true)
    }
}

