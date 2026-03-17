import SwiftUI
import SwiftData

struct NowPlayingView: View {

    @EnvironmentObject private var playerVM: PlayerViewModel
    @EnvironmentObject private var theme: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var showAddToPlaylistSheet = false
    @State private var showQueueSheet = false
    @State private var swipeOffsetX: CGFloat = 0

    private var colors: WavloColors { theme.colors }

    /// Vertical gradient: darkened dominant color at top → theme primary at bottom (Spotify-style). Optional blur overlay.
    private var nowPlayingBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    playerVM.dominantBackgroundColor ?? colors.bgPrimary,
                    colors.bgPrimary
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            Rectangle()
                .fill(.ultraThinMaterial.opacity(0.12))
                .ignoresSafeArea()
        }
    }

    var body: some View {
        ZStack {
            nowPlayingBackground
            if let song = playerVM.currentSong {
                VStack(spacing: 0) {
                    header(song: song)
                    nowPlayingContent(song: song)
                    progressSection
                    playbackControls()
                    bottomRow
                }
                .padding(.vertical, 24)
            } else {
                emptyState
            }
        }
        .presentationDetents([.large])
        .sheet(isPresented: $showAddToPlaylistSheet) {
            if let song = playerVM.currentSong {
                AddToPlaylistSheet(song: song)
                    .environmentObject(theme)
            }
        }
        .sheet(isPresented: $showQueueSheet) {
            QueueView()
                .environmentObject(playerVM)
                .environmentObject(theme)
                .presentationDetents([.medium, .large])
        }
    }

    private func header(song: Song) -> some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(colors.textPrimary)
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
                    showAddToPlaylistSheet = true
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
        let drag = DragGesture(minimumDistance: 20)
            .onChanged { value in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    swipeOffsetX = max(-24, min(24, value.translation.width))
                }
            }
            .onEnded { value in
                let width = value.translation.width
                if width < -50 {
                    playerVM.skipToNext()
                } else if width > 50 {
                    playerVM.skipToPrevious()
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    swipeOffsetX = 0
                }
            }

        return VStack(spacing: 32) {
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
        .offset(x: swipeOffsetX)
        .highPriorityGesture(drag)
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

    private var bottomRow: some View {
        HStack(spacing: 12) {
            if let device = playerVM.currentOutputDevice {
                HStack(spacing: 6) {
                    Image(systemName: device.iconSystemName)
                        .font(.system(size: 14, weight: .medium))
                    Text(device.name)
                        .font(Constants.Typography.caption)
                        .lineLimit(1)
                }
                .foregroundStyle(WavloColors.accentGreen)
            }
            Spacer()
            HStack(spacing: 18) {
                Button {
                    // Share (stub)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(colors.textSecondary)
                }
                .buttonStyle(.plain)

                Button {
                    showQueueSheet = true
                } label: {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(colors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.top, 14)
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
