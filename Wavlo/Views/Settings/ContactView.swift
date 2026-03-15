import SwiftUI

struct ContactView: View {

    @EnvironmentObject private var theme: ThemeManager
    private var colors: WavloColors { theme.colors }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 8) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(colors.primaryAccent)
                    Text("We'd love to hear from you")
                        .font(Constants.Typography.bodyLarge)
                        .foregroundStyle(colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .listRowBackground(colors.bgCard)

            Section("Contact") {
                linkRow(icon: "envelope.fill", title: "Email", value: "wavloapp@gmail.com", url: "mailto:wavloapp@gmail.com")
                linkRow(icon: "link", title: "Twitter / X", value: "@wavloapp", url: "https://twitter.com/wavloapp")
                linkRow(icon: "camera.fill", title: "Instagram", value: "@wavloapp", url: "https://instagram.com/wavloapp")
                linkRow(icon: "globe", title: "Website", value: "wavlo.app", url: "https://wavlo.app")
            }
            .listRowBackground(colors.bgCard)
            .foregroundStyle(colors.textPrimary)

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Have a question?")
                        .font(Constants.Typography.titleMedium)
                        .foregroundStyle(colors.textPrimary)
                    Text("Check our FAQ section first — most common questions are answered there.")
                        .font(Constants.Typography.bodySmall)
                        .foregroundStyle(colors.textSecondary)
                    Text("For bug reports, please include:")
                        .font(Constants.Typography.bodySmall)
                        .foregroundStyle(colors.textPrimary)
                        .padding(.top, 4)
                    Text("• Your device model\n• iOS version\n• Steps to reproduce the issue")
                        .font(Constants.Typography.bodySmall)
                        .foregroundStyle(colors.textSecondary)
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(colors.bgCard)

            Section {
                VStack(spacing: 4) {
                    Text("Made with ❤️ by Vatsalya")
                        .font(Constants.Typography.bodySmall)
                        .foregroundStyle(colors.textSecondary)
                    Text("Version \(appVersion)")
                        .font(Constants.Typography.caption)
                        .foregroundStyle(colors.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .listRowBackground(colors.bgPrimary)
        }
        .scrollContentBackground(.hidden)
        .background(colors.bgPrimary)
        .navigationTitle("Contact Us")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func linkRow(icon: String, title: String, value: String, url: String) -> some View {
        Button {
            if let u = URL(string: url) {
                UIApplication.shared.open(u)
            }
        } label: {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24, alignment: .center)
                    .foregroundStyle(colors.primaryAccent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Constants.Typography.bodySmall)
                        .foregroundStyle(colors.textMuted)
                    Text(value)
                        .font(Constants.Typography.bodyRegular)
                        .foregroundStyle(colors.textPrimary)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12))
                    .foregroundStyle(colors.textMuted)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ContactView()
            .environmentObject(ThemeManager())
    }
}
