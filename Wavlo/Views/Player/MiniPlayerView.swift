import SwiftUI
import SwiftData

struct MiniPlayerView: View {

    @EnvironmentObject private var playerVM: PlayerViewModel
    @EnvironmentObject private var theme: ThemeManager
    @State private var showNowPlaying = false
    @State private var dragOffsetX: CGFloat = 0

    private var colors: WavloColors { theme.colors }

    private var progress: Double {
        guard playerVM.duration > 0 else { return 0 }
        return playerVM.currentTime / playerVM.duration
    }

    private var firstArtist: String {
        guard let name = playerVM.currentSong?.artistName, !name.isEmpty else {
            return "Tap to open player"
        }
        return name.split(separator: ",").first.map { String($0).trimmingCharacters(in: .whitespaces) } ?? name
    }

    var body: some View {
        let drag = DragGesture(minimumDistance: 20)
            .onChanged { value in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    dragOffsetX = max(-20, min(20, value.translation.width))
                }
            }
            .onEnded { value in
                let width = value.translation.width
                // swipe right-to-left → next, swipe left-to-right → previous.
                if width < -40 {
                    playerVM.skipToNext()
                } else if width > 40 {
                    playerVM.skipToPrevious()
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    dragOffsetX = 0
                }
            }

        Button {
            showNowPlaying = true
        } label: {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
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

                        VStack(alignment: .leading, spacing: 2) {
                            Text(playerVM.currentSong?.title ?? "Not playing")
                                .font(Constants.Typography.bodyLarge)
                                .fontWeight(.semibold)
                                .foregroundStyle(colors.textPrimary)
                                .lineLimit(1)
                            Text(firstArtist)
                                .font(Constants.Typography.bodySmall)
                                .foregroundStyle(colors.textSecondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .offset(x: dragOffsetX)

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
            .background(
                ZStack {
                    colors.bgCard
                    if let dominant = playerVM.dominantBackgroundColor {
                        dominant.opacity(0.65)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.miniPlayerCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .highPriorityGesture(drag)
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
