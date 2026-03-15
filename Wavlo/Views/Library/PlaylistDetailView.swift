import SwiftUI
import SwiftData

struct PlaylistDetailView: View {

    @Bindable var playlist: Playlist
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var playerVM: PlayerViewModel
    @EnvironmentObject private var theme: ThemeManager
    @StateObject private var libraryVM = LibraryViewModel()

    private var colors: WavloColors { theme.colors }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let url = playlist.coverImageURL.flatMap(URL.init) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                        default:
                            RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius)
                                .fill(colors.bgElevated)
                        }
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius, style: .continuous))
                }
                Text(playlist.name)
                    .font(Constants.Typography.titleLarge)
                    .foregroundStyle(colors.textPrimary)
                Text("\(playlist.songs.count) songs")
                    .font(Constants.Typography.bodyRegular)
                    .foregroundStyle(colors.textSecondary)

                if playlist.songs.isEmpty {
                    Text("No songs yet. Add from Search or Home.")
                        .font(Constants.Typography.bodyRegular)
                        .foregroundStyle(colors.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                } else {
                    LazyVStack(spacing: Constants.Layout.baseSpacing) {
                        ForEach(Array(playlist.songs.enumerated()), id: \.element.id) { index, song in
                            SongRowView(
                                song: song,
                                onTap: {
                                    playerVM.play(songs: Array(playlist.songs), startIndex: index)
                                },
                                onLike: { playerVM.toggleLike(song) }
                            )
                        }
                    }
                }
            }
            .wavloScreenPadding()
            .padding(.bottom, 100)
        }
        .scrollContentBackground(.hidden)
        .background(colors.bgPrimary)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Song.self, Playlist.self, configurations: config)
    let playlist = Playlist(id: "1", name: "Favorites", songs: [])
    container.mainContext.insert(playlist)
    return NavigationStack {
        PlaylistDetailView(playlist: playlist)
            .environmentObject(PlayerViewModel.shared)
            .environmentObject(ThemeManager())
            .modelContainer(container)
    }
}
