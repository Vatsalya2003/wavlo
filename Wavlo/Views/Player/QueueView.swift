import SwiftUI
import SwiftData

struct QueueView: View {

    @EnvironmentObject private var playerVM: PlayerViewModel
    @EnvironmentObject private var theme: ThemeManager
    let queue: [Song]
    let onSelect: (Int) -> Void

    private var colors: WavloColors { theme.colors }

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Layout.baseSpacing) {
            Text("Up Next")
                .font(Constants.Typography.titleMedium)
                .foregroundStyle(colors.textPrimary)
            ForEach(Array(queue.enumerated()), id: \.element.id) { index, song in
                Button {
                    onSelect(index)
                } label: {
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(Constants.Typography.pill)
                            .foregroundStyle(colors.textMuted)
                            .frame(width: 24, alignment: .leading)
                        AsyncImage(url: URL(string: song.artworkURL)) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().aspectRatio(contentMode: .fill)
                            default:
                                Rectangle().fill(colors.bgElevated)
                            }
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.smallCornerRadius, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(song.title)
                                .font(Constants.Typography.bodyRegular)
                                .foregroundStyle(colors.textPrimary)
                                .lineLimit(1)
                            Text(song.artistName)
                                .font(Constants.Typography.caption)
                                .foregroundStyle(colors.textSecondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Constants.Layout.cardPadding)
        .background(colors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius, style: .continuous))
    }
}

#Preview {
    let songs = (1...3).map { i in
        Song(id: "\(i)", title: "Track \(i)", artistName: "Artist", albumName: "", genre: "Pop", streamURL: "", artworkURL: "", duration: 180)
    }
    return QueueView(queue: songs, onSelect: { _ in })
        .environmentObject(PlayerViewModel.shared)
        .environmentObject(ThemeManager())
        .padding()
        .background(Color(hex: "0d0d0d"))
}
