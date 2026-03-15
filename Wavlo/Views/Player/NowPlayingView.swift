import SwiftUI
import SwiftData

struct NowPlayingView: View {

    @EnvironmentObject private var playerVM: PlayerViewModel
    @EnvironmentObject private var theme: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var showLyricsTab = false
    @State private var lyricsText: String?
    @State private var isLoadingLyrics = false

    private var colors: WavloColors { theme.colors }

    var body: some View {
        ZStack {
            colors.bgPrimary.ignoresSafeArea()
            if let song = playerVM.currentSong {
                VStack(spacing: 0) {
                    header(song: song)

                    if showLyricsTab {
                        lyricsContent(song: song)
                    } else {
                        nowPlayingContent(song: song)
                    }

                    progressSection
                    playbackControls()
                }
                .padding(.vertical, 24)
            } else {
                emptyState
            }
        }
        .presentationDetents([.large])
    }

    private func header(song: Song) -> some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(colors.textPrimary)
            }
            Spacer()
            HStack(spacing: 20) {
                Button {
                    showLyricsTab = false
                } label: {
                    Text("Now Playing")
                        .font(Constants.Typography.caption)
                        .foregroundStyle(showLyricsTab ? colors.textSecondary : colors.primaryAccent)
                }
                Button {
                    showLyricsTab = true
                    fetchLyrics(songId: song.id)
                } label: {
                    Text("Lyrics")
                        .font(Constants.Typography.caption)
                        .foregroundStyle(showLyricsTab ? colors.primaryAccent : colors.textSecondary)
                }
            }
            Spacer()
            HStack(spacing: 16) {
                Button {
                    playerVM.toggleLike(song)
                } label: {
                    Image(systemName: song.isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 22))
                        .foregroundStyle(song.isLiked ? colors.primaryAccent : colors.textPrimary)
                }
                .buttonStyle(.plain)
                Button {
                    // More options: add to playlist, share, etc. (stub)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(colors.textPrimary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
    }

    private func nowPlayingContent(song: Song) -> some View {
        VStack(spacing: 32) {
            AsyncImage(url: URL(string: song.artworkURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius)
                        .fill(colors.bgElevated)
                default:
                    ProgressView()
                }
            }
            .frame(width: Constants.Layout.artworkSizeLarge, height: Constants.Layout.artworkSizeLarge)
            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)

            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(colors.textPrimary)
                    .lineLimit(1)
                Text(song.artistName)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(colors.textSecondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 4)
        }
    }

    private func lyricsContent(song: Song) -> some View {
        Group {
            if isLoadingLyrics {
                ProgressView()
                    .tint(colors.primaryAccent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let text = lyricsText, !text.isEmpty {
                LyricsView(
                    lyrics: text,
                    duration: Double(song.duration),
                    currentTime: playerVM.currentTime,
                    songTitle: song.title,
                    artistName: song.artistName,
                    albumName: song.albumName,
                    artworkURL: song.artworkURL
                )
            } else {
                VibeCardView(
                    title: "No lyrics available",
                    subtitle: "Enjoy the music",
                    imageURL: nil,
                    accentColor: WavloColors.accentTeal
                )
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(.bottom, 8)
    }

    private var progressSection: some View {
        VStack(spacing: 8) {
            SlimProgressBar(
                progress: playerVM.duration > 0 ? playerVM.currentTime / playerVM.duration : 0,
                colors: colors,
                onSeek: { progress in playerVM.seek(to: progress) }
            )
            .padding(.horizontal)

            HStack(spacing: 8) {
                Text(formatTime(playerVM.currentTime))
                    .font(Constants.Typography.caption)
                    .foregroundStyle(colors.textMuted)
                Spacer()
                Text(formatTime(playerVM.duration))
                    .font(Constants.Typography.caption)
                    .foregroundStyle(colors.textMuted)
            }
            .padding(.horizontal)
        }
    }

    private func playbackControls() -> some View {
        HStack(spacing: 40) {
            Button { playerVM.skipToPrevious() } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(colors.textPrimary)
            }
            Button { playerVM.togglePlayPause() } label: {
                Image(systemName: playerVM.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(colors.primaryAccent)
            }
            Button { playerVM.skipToNext() } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(colors.textPrimary)
            }
        }
        .padding(.top, 24)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("Nothing playing")
                .font(Constants.Typography.titleLarge)
                .foregroundStyle(colors.textSecondary)
            Button { dismiss() } label: {
                Text("Close")
                    .font(Constants.Typography.titleMedium)
                    .foregroundStyle(colors.primaryAccent)
            }
        }
    }

    private func fetchLyrics(songId: String) {
        lyricsText = nil
        isLoadingLyrics = true
        Task {
            let service = LyricsService()
            lyricsText = try? await service.fetchLyrics(songId: songId)
            await MainActor.run {
                isLoadingLyrics = false
            }
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}

#Preview {
    NowPlayingView()
        .environmentObject(PlayerViewModel.shared)
        .environmentObject(ThemeManager())
}
