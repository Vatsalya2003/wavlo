import SwiftUI
import SwiftData

struct MiniPlayerView: View {

    @EnvironmentObject private var playerVM: PlayerViewModel
    @EnvironmentObject private var theme: ThemeManager
    @State private var showNowPlaying = false

    private var colors: WavloColors { theme.colors }

    private var progress: Double {
        guard playerVM.duration > 0 else { return 0 }
        return playerVM.currentTime / playerVM.duration
    }

    var body: some View {
        Button {
            showNowPlaying = true
        } label: {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    AsyncImage(url: playerVM.currentSong.flatMap { URL(string: $0.artworkURL) }) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                        default:
                            RoundedRectangle(cornerRadius: 6)
                                .fill(colors.bgElevated)
                        }
                    }
                    .frame(width: Constants.Layout.miniPlayerArtworkSize, height: Constants.Layout.miniPlayerArtworkSize)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                    HStack(spacing: 4) {
                        Text(playerVM.currentSong?.title ?? "Not playing")
                            .font(Constants.Typography.bodyLarge)
                            .fontWeight(.semibold)
                            .foregroundStyle(colors.textPrimary)
                            .lineLimit(1)
                        Text("•")
                            .font(Constants.Typography.bodySmall)
                            .foregroundStyle(colors.textSecondary)
                        Text(playerVM.currentSong?.artistName ?? "Tap to open player")
                            .font(Constants.Typography.bodySmall)
                            .foregroundStyle(colors.textSecondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        playerVM.togglePlayPause()
                    } label: {
                        Image(systemName: playerVM.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(colors.primaryAccent)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(colors.borderSubtle)
                            .frame(height: 2)
                        Rectangle()
                            .fill(WavloColors.accentGreen)
                            .frame(width: geo.size.width * progress, height: 2)
                    }
                }
                .frame(height: 2)
            }
            .frame(height: Constants.Layout.miniPlayerHeight + 2)
            .background(colors.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.miniPlayerCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showNowPlaying) {
            NowPlayingView()
                .environmentObject(playerVM)
                .environmentObject(theme)
        }
    }
}

#Preview {
    MiniPlayerView()
        .environmentObject(PlayerViewModel.shared)
        .environmentObject(ThemeManager())
        .background(Color(hex: "0d0d0d"))
}
