import SwiftUI

struct LyricsView: View {

    let lyrics: String
    let source: LyricsSource
    @EnvironmentObject private var theme: ThemeManager

    private var colors: WavloColors { theme.colors }

    private var lines: [String] {
        lyrics
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private var caption: String {
        switch source {
        case .jiosaavn: return "Lyrics from JioSaavn"
        case .gemini: return "Lyrics provided by AI"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                Text(caption)
                    .font(Constants.Typography.caption)
                    .foregroundStyle(colors.textMuted)
                    .padding(.top, 24)
            }
            .padding(.vertical, 32)
            .padding(.horizontal)
        }
    }
}

#Preview {
    LyricsView(
        lyrics: "Line one\nLine two\nLine three\nLine four",
        source: .gemini
    )
    .environmentObject(ThemeManager())
    .background(Color(hex: "0d0d0d"))
}
