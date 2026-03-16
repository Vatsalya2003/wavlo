import SwiftUI
import SwiftData

struct QueueView: View {

    @EnvironmentObject private var playerVM: PlayerViewModel
    @EnvironmentObject private var theme: ThemeManager

    private var colors: WavloColors { theme.colors }

    var body: some View {
        VStack(spacing: 12) {
            Capsule()
                .fill(Color.gray.opacity(0.35))
                .frame(width: 36, height: 4)
                .padding(.top, 8)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Queue")
                        .font(Constants.Typography.titleMedium)
                        .foregroundStyle(colors.textPrimary)
                    Text("Playing Queue")
                        .font(Constants.Typography.bodySmall)
                        .foregroundStyle(colors.textSecondary)
                }
                Spacer()
                Button("Clear") {
                    playerVM.clearUpcomingQueue()
                }
                .font(Constants.Typography.bodySmall)
                .foregroundStyle(colors.textSecondary)
            }
            .padding(.horizontal, 16)

            List {
                ForEach(Array(playerVM.queue.enumerated()), id: \.element.id) { index, song in
                    let isCurrent = song.id == playerVM.currentSong?.id
                    HStack(spacing: 12) {
                        AsyncImage(url: URL(string: song.artworkURL)) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().aspectRatio(contentMode: .fill)
                            default:
                                Rectangle().fill(colors.bgElevated)
                            }
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                if isCurrent {
                                    Image(systemName: "waveform")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(WavloColors.accentGreen)
                                }
                                Text(song.title)
                                    .font(Constants.Typography.bodyLarge)
                                    .foregroundStyle(isCurrent ? WavloColors.accentGreen : colors.textPrimary)
                                    .lineLimit(1)
                            }
                            Text(song.artistName)
                                .font(Constants.Typography.caption)
                                .foregroundStyle(colors.textSecondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        if isCurrent {
                            Button {
                                playerVM.togglePlayPause()
                            } label: {
                                Image(systemName: playerVM.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(colors.primaryAccent)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(colors.textSecondary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        playerVM.playFromQueueIndex(index)
                    }
                    .swipeActions {
                        if !isCurrent {
                            Button(role: .destructive) {
                                playerVM.removeFromQueue(at: IndexSet(integer: index))
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                    .moveDisabled(isCurrent)
                }
                .onMove { source, destination in
                    playerVM.moveQueue(from: source, to: destination)
                }
            }
            .listStyle(.plain)
            .environment(\.editMode, .constant(.active))

            HStack(spacing: 12) {
                outlineToggleButton(icon: "shuffle", title: "Shuffle", isOn: playerVM.isShuffleOn) {
                    playerVM.isShuffleOn.toggle()
                }
                outlineToggleButton(icon: "repeat", title: "Repeat", isOn: playerVM.isRepeatOn) {
                    playerVM.isRepeatOn.toggle()
                }
                outlineToggleButton(icon: "timer", title: "Timer", isOn: playerVM.isSleepTimerOn) {
                    playerVM.isSleepTimerOn.toggle()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(colors.bgPrimary.ignoresSafeArea())
    }

    private func outlineToggleButton(icon: String, title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(Constants.Typography.bodySmall)
            .foregroundStyle(isOn ? WavloColors.accentGreen : colors.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .overlay(
                Capsule()
                    .stroke(isOn ? WavloColors.accentGreen : colors.textSecondary.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let songs = (1...3).map { i in
        Song(id: "\(i)", title: "Track \(i)", artistName: "Artist", albumName: "", genre: "Pop", streamURL: "", artworkURL: "", duration: 180)
    }
    PlayerViewModel.shared.queue = songs
    PlayerViewModel.shared.currentSong = songs.first
    return QueueView()
        .environmentObject(PlayerViewModel.shared)
        .environmentObject(ThemeManager())
        .background(Color(hex: "0d0d0d"))
}
