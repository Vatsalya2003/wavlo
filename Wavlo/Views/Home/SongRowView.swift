import SwiftUI
import SwiftData

struct SongRowView: View {

    let song: Song
    let onTap: () -> Void
    let onLike: () -> Void
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var playerVM: PlayerViewModel

    private var colors: WavloColors { theme.colors }

    private var isCurrentSong: Bool {
        playerVM.currentSong?.id == song.id
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: song.artworkURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Rectangle()
                            .fill(colors.bgElevated)
                    default:
                        ProgressView()
                    }
                }
                .frame(width: Constants.Layout.songRowArtworkSize, height: Constants.Layout.songRowArtworkSize)
                .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.songRowCornerRadius, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title)
                        .font(Constants.Typography.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundStyle(colors.textPrimary)
                        .lineLimit(1)
                    Text(song.artistName)
                        .font(Constants.Typography.bodySmall)
                        .foregroundStyle(colors.textSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isCurrentSong {
                    Button {
                        playerVM.togglePlayPause()
                    } label: {
                        Image(systemName: playerVM.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(colors.primaryAccent)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: onLike) {
                        Image(systemName: song.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 18))
                            .foregroundStyle(song.isLiked ? colors.primaryAccent : colors.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minHeight: 64)
            .background(colors.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let song = Song(
        id: "1",
        title: "Sample Track",
        artistName: "Artist",
        albumName: "Album",
        genre: "Pop",
        streamURL: "https://example.com/a.mp3",
        artworkURL: "",
        duration: 180
    )
    return SongRowView(song: song, onTap: {}, onLike: {})
        .environmentObject(ThemeManager())
        .environmentObject(PlayerViewModel.shared)
        .padding()
        .background(Color(hex: "0d0d0d"))
}
