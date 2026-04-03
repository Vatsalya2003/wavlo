import SwiftUI

enum RecommendationCardLayout {
    case compact
    case full
}

struct RecommendationCardView: View {

    let recommendation: MLRecommendation
    let layout: RecommendationCardLayout
    let onTap: () -> Void

    @EnvironmentObject private var theme: ThemeManager
    private var colors: WavloColors { theme.colors }

    private var width: CGFloat? {
        switch layout {
        case .compact: return 200
        case .full: return nil
        }
    }

    private var reasonColor: Color {
        switch recommendation.reason {
        case .becauseYouLiked, .personalMix, .sessionFlow:
            return Color(hex: "7F77DD") // accent purple
        case .moodMatch, .discoverNew, .artistDeepDive:
            return Color(hex: "5DCAA5") // accent teal
        }
    }

    var body: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onTap()
        } label: {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: recommendation.song.artworkURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colors.bgElevated)
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.song.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(colors.textPrimary)
                        .lineLimit(1)
                    Text(recommendation.song.artistName)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(colors.textSecondary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(recommendation.reason.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(colors.bgPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(reasonColor)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                        let similarityPercent = Int((recommendation.similarityScore * 100).rounded())
                        Text("Similarity: \(similarityPercent)%")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(colors.textMuted)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(width: width, alignment: .leading)
            .background(Color(hex: "111111"))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let song = Song(
        id: "demo",
        title: "Midnight Drive",
        artistName: "Neon Waves",
        albumName: "City Lights",
        genre: "electronic, chillout",
        streamURL: "https://example.com",
        artworkURL: "",
        duration: 240
    )
    let rec = MLRecommendation(song: song,
                               score: 0.9,
                               reason: .becauseYouLiked,
                               skipProbability: 0.1,
                               similarityScore: 0.87)
    return RecommendationCardView(
        recommendation: rec,
        layout: .compact,
        onTap: {}
    )
    .environmentObject(ThemeManager())
    .background(Color(hex: "0d0d0d"))
}

