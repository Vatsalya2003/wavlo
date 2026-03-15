import SwiftUI
import SwiftData

struct SongSuggestionCardView: View {

    let song: Song
    let onPlay: () -> Void
    @EnvironmentObject private var theme: ThemeManager

    private var colors: WavloColors { theme.colors }

    var body: some View {
        Button(action: onPlay) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: song.artworkURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        Rectangle().fill(colors.bgElevated)
                    }
                }
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.smallCornerRadius, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title)
                        .font(Constants.Typography.bodyLarge)
                        .foregroundStyle(colors.textPrimary)
                        .lineLimit(1)
                    Text(song.artistName)
                        .font(Constants.Typography.caption)
                        .foregroundStyle(colors.textSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(colors.primaryAccent)
            }
            .padding(Constants.Layout.baseSpacing)
            .background(colors.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let song = Song(id: "1", title: "Chill Beat", artistName: "Artist", albumName: "", genre: "Chill", streamURL: "", artworkURL: "", duration: 180)
    return SongSuggestionCardView(song: song, onPlay: {})
        .environmentObject(ThemeManager())
        .padding()
        .background(Color(hex: "0d0d0d"))
}
