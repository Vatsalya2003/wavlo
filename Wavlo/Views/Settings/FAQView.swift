import SwiftUI

struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

private let faqItems: [FAQItem] = [
    FAQItem(
        question: "Is Wavlo free to use?",
        answer: "Yes! Wavlo is completely free. Stream unlimited songs, use the AI DJ, and create playlists — all at zero cost."
    ),
    FAQItem(
        question: "How does Wavlo DJ work?",
        answer: "Wavlo DJ is your AI-powered music companion. Just tell it your mood, situation, or what you're feeling — and it suggests the perfect songs. It understands context like 'I miss my girlfriend' or 'gym workout mode' and picks real, popular tracks."
    ),
    FAQItem(
        question: "Where does the music come from?",
        answer: "Wavlo streams music from a vast catalog of songs across Hindi, English, Punjabi, Tamil, Telugu, and many more languages. We source music through licensed streaming APIs."
    ),
    FAQItem(
        question: "Can I use Wavlo offline?",
        answer: "Currently, Wavlo requires an internet connection to stream music. Offline download support is planned for a future update."
    ),
    FAQItem(
        question: "How do I change the theme?",
        answer: "Go to Settings → Content and display → Theme. You can switch between Dark mode and Light mode."
    ),
    FAQItem(
        question: "What is voice search?",
        answer: "Tap the mic icon in the search bar and speak what you want — a song name, artist, mood, or even a situation like 'play something for a road trip'. Wavlo will find it for you."
    ),
    FAQItem(
        question: "Does Wavlo collect my data?",
        answer: "Wavlo stores your listening history and preferences locally on your device only. We do not collect, sell, or share any personal data with third parties."
    ),
    FAQItem(
        question: "How do I report a bug or give feedback?",
        answer: "Go to Settings → About → Contact Us. You can email us directly with your feedback or bug report."
    ),
    FAQItem(
        question: "Why are some songs not available?",
        answer: "Song availability depends on licensing and regional restrictions. If a specific song isn't available, try searching for an alternate version or a different artist."
    ),
    FAQItem(
        question: "Can I create my own playlists?",
        answer: "Yes! Go to Your Library → tap the + button to create a new playlist. You can add songs from anywhere in the app."
    )
]

struct FAQView: View {

    @EnvironmentObject private var theme: ThemeManager
    private var colors: WavloColors { theme.colors }

    var body: some View {
        List {
            ForEach(faqItems) { item in
                DisclosureGroup {
                    Text(item.answer)
                        .font(Constants.Typography.bodyRegular)
                        .foregroundStyle(colors.textSecondary)
                        .padding(.vertical, 4)
                } label: {
                    Text(item.question)
                        .font(Constants.Typography.bodyLarge)
                        .fontWeight(.medium)
                        .foregroundStyle(colors.textPrimary)
                }
                .tint(colors.primaryAccent)
                .listRowBackground(colors.bgCard)
            }
        }
        .scrollContentBackground(.hidden)
        .background(colors.bgPrimary)
        .navigationTitle("FAQ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        FAQView()
            .environmentObject(ThemeManager())
    }
}
