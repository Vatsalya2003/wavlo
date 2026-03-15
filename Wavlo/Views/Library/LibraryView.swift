import SwiftUI
import SwiftData

struct LibraryView: View {

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var theme: ThemeManager
    @Query(sort: \Playlist.createdAt, order: .reverse) private var playlists: [Playlist]
    @Query(sort: \Song.playCount, order: .reverse) private var topSongs: [Song]
    @EnvironmentObject private var playerVM: PlayerViewModel
    @StateObject private var libraryVM = LibraryViewModel()
    @State private var showNewPlaylist = false
    @State private var newPlaylistName = ""

    private var colors: WavloColors { theme.colors }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Section {
                        ForEach(playlists) { playlist in
                            NavigationLink {
                                PlaylistDetailView(playlist: playlist)
                                    .environmentObject(playerVM)
                                    .environmentObject(theme)
                            } label: {
                                HStack(spacing: 12) {
                                    AsyncImage(url: playlist.coverImageURL.flatMap(URL.init)) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        default:
                                            Rectangle()
                                                .fill(colors.bgElevated)
                                        }
                                    }
                                    .frame(width: 56, height: 56)
                                    .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.smallCornerRadius, style: .continuous))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(playlist.name)
                                            .font(Constants.Typography.titleMedium)
                                            .foregroundStyle(colors.textPrimary)
                                        Text("\(playlist.songs.count) songs")
                                            .font(Constants.Typography.bodySmall)
                                            .foregroundStyle(colors.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(Constants.Layout.baseSpacing)
                                .background(colors.bgCard)
                                .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Text("Playlists")
                            .font(Constants.Typography.titleLarge)
                            .foregroundStyle(colors.textPrimary)
                    }

                    if !topSongs.isEmpty {
                        Section {
                            ForEach(topSongs.prefix(15), id: \.id) { song in
                                SongRowView(
                                    song: song,
                                    onTap: {
                                        if let idx = topSongs.firstIndex(where: { $0.id == song.id }) {
                                            playerVM.play(songs: Array(topSongs), startIndex: idx)
                                        }
                                    },
                                    onLike: { playerVM.toggleLike(song) }
                                )
                            }
                        } header: {
                            Text("Most played")
                                .font(Constants.Typography.titleLarge)
                                .foregroundStyle(colors.textPrimary)
                        }
                    }
                }
                .wavloScreenPadding()
                .padding(.bottom, playerVM.currentSong != nil ? 170 : 100)
            }
            .scrollContentBackground(.hidden)
            .background(colors.bgPrimary)
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewPlaylist = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(colors.primaryAccent)
                    }
                }
            }
            .alert("New Playlist", isPresented: $showNewPlaylist) {
                TextField("Playlist name", text: $newPlaylistName)
                Button("Cancel", role: .cancel) {
                    newPlaylistName = ""
                }
                Button("Create") {
                    _ = libraryVM.createPlaylist(name: newPlaylistName.isEmpty ? "New Playlist" : newPlaylistName, context: modelContext)
                    newPlaylistName = ""
                }
            } message: {
                Text("Enter a name for your playlist.")
            }
        }
    }
}

#Preview {
    LibraryView()
        .environmentObject(PlayerViewModel.shared)
        .environmentObject(ThemeManager())
        .modelContainer(for: [Song.self, Playlist.self, ListeningHistory.self, UserPreferences.self], inMemory: true)
}
