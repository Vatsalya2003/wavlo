import SwiftUI

struct AboutView: View {

    @EnvironmentObject private var theme: ThemeManager
    private var colors: WavloColors { theme.colors }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(colors.primaryAccent)
                    Text("Wavlo v\(appVersion)")
                        .font(Constants.Typography.titleMedium)
                        .foregroundStyle(colors.textPrimary)
                    Text("Music that knows you.")
                        .font(Constants.Typography.bodyRegular)
                        .foregroundStyle(colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
            .listRowBackground(colors.bgCard)

            Section("About Wavlo") {
                Text("Wavlo is a free, AI-powered music streaming app that learns your taste and plays what you love. Powered by an intelligent DJ that understands your mood, moment, and vibe.")
                    .font(Constants.Typography.bodyRegular)
                    .foregroundStyle(colors.textSecondary)
            }
            .listRowBackground(colors.bgCard)

            Section("Features") {
                featureRow(icon: "music.note", text: "Stream millions of songs for free")
                featureRow(icon: "waveform.circle", text: "AI-powered Wavlo DJ — tell your mood, get the perfect playlist")
                featureRow(icon: "mic.fill", text: "Voice search — just say what you want")
                featureRow(icon: "text.alignleft", text: "Synced lyrics on Now Playing")
                featureRow(icon: "heart.fill", text: "Mood-based playlists — Chill, Party, Romantic, Workout, and more")
                featureRow(icon: "moon.fill", text: "Dark & Light theme support")
                featureRow(icon: "lock.fill", text: "No ads, no tracking, fully private")
                featureRow(icon: "iphone", text: "Background playback with lock screen controls")
            }
            .listRowBackground(colors.bgCard)

            Section("Resources & Credits") {
                Text("• Music powered by JioSaavn")
                Text("• AI powered by Google Gemini")
                Text("• Voice recognition by Apple Speech")
                Text("• Built with SwiftUI & SwiftData")
            }
            .listRowBackground(colors.bgCard)
            .foregroundStyle(colors.textSecondary)

            Section {
                NavigationLink("Privacy Policy") { PrivacyPolicyView() }
                NavigationLink("Terms of Service") { TermsPlaceholderView() }
                NavigationLink("Open Source Licenses") { LicensesPlaceholderView() }
            }
            .listRowBackground(colors.bgCard)
            .foregroundStyle(colors.textPrimary)

            Section {
                NavigationLink("FAQ") { FAQView() }
                NavigationLink("Contact Us") { ContactView() }
            }
            .listRowBackground(colors.bgCard)
            .foregroundStyle(colors.textPrimary)
        }
        .scrollContentBackground(.hidden)
        .background(colors.bgPrimary)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(colors.primaryAccent)
                .frame(width: 24, alignment: .center)
            Text(text)
                .font(Constants.Typography.bodyRegular)
                .foregroundStyle(colors.textPrimary)
        }
    }
}

private struct TermsPlaceholderView: View {
    @EnvironmentObject private var theme: ThemeManager
    var body: some View {
        Text("Terms of Service — coming soon")
            .foregroundStyle(theme.colors.textMuted)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.colors.bgPrimary)
            .navigationTitle("Terms of Service")
    }
}

private struct LicensesPlaceholderView: View {
    @EnvironmentObject private var theme: ThemeManager
    var body: some View {
        Text("Open Source Licenses — coming soon")
            .foregroundStyle(theme.colors.textMuted)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.colors.bgPrimary)
            .navigationTitle("Open Source Licenses")
    }
}

#Preview {
    NavigationStack {
        AboutView()
            .environmentObject(ThemeManager())
    }
}
