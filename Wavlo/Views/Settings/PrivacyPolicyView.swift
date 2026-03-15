import SwiftUI

private let privacyPolicyText = """
Privacy Policy for Wavlo

Last updated: March 2026

1. Information We Collect
Wavlo stores your listening history, liked songs, and playlists locally on your device. We do not collect personal information or transmit your data to external servers.

2. AI Features
When you use Wavlo DJ, your text messages are sent to Google's Gemini API to generate music recommendations. No personal identifiers are included in these requests.

3. Music Streaming
Music is streamed from third-party sources. We do not store or cache copyrighted music on our servers.

4. Data Storage
All user preferences, playlists, and history are stored locally using Apple's SwiftData framework on your device only.

5. Third-Party Services
• Google Gemini API — for AI DJ chat responses
• JioSaavn — for music catalog and streaming
• Apple Speech Framework — for voice recognition (processed on-device)

6. Children's Privacy
Wavlo is not directed at children under 13.

7. Changes to This Policy
We may update this policy from time to time. Changes will be reflected in the app.

8. Contact
For privacy concerns, email: wavloapp@gmail.com
"""

struct PrivacyPolicyView: View {

    @EnvironmentObject private var theme: ThemeManager
    private var colors: WavloColors { theme.colors }

    var body: some View {
        ScrollView {
            Text(privacyPolicyText)
                .font(Constants.Typography.bodyRegular)
                .foregroundStyle(colors.textPrimary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollContentBackground(.hidden)
        .background(colors.bgPrimary)
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
            .environmentObject(ThemeManager())
    }
}
