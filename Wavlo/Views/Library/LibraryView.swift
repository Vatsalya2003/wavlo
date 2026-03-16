import SwiftUI
import SwiftData

struct LibraryView: View {

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var theme: ThemeManager
    @Query(sort: \Playlist.createdAt, order: .reverse) private var playlists: [Playlist]
    @Query(sort: \Song.addedAt, order: .reverse) private var allSongs: [Song]
    @Query(sort: \Song.playCount, order: .reverse) private var topSongs: [Song]
    @EnvironmentObject private var playerVM: PlayerViewModel
    @StateObject private var libraryVM = LibraryViewModel()
    @State private var showNewPlaylist = false
    @State private var newPlaylistName = ""
    @State private var playlistToDelete: Playlist?
    @State private var showDeleteAlert = false
    @State private var renamingPlaylist: Playlist?
    @State private var renameText: String = ""

    private var colors: WavloColors { theme.colors }
    private var likedSongs: [Song] { allSongs.filter { $0.isLiked } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    likedSongsSection()
                    playlistsSection()
                    topSongsSection()
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
                    if !playlists.isEmpty {
                        Button {
                            showNewPlaylist = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(colors.primaryAccent)
                        }
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
            .alert("Delete Playlist?", isPresented: $showDeleteAlert, presenting: playlistToDelete) { playlist in
                Button("Cancel", role: .cancel) { playlistToDelete = nil }
                Button("Delete", role: .destructive) {
                    libraryVM.deletePlaylist(playlist, context: modelContext)
                    playlistToDelete = nil
                }
            } message: { playlist in
                Text("Are you sure you want to delete \"\(playlist.name)\"? This can't be undone.")
            }
            .alert("Rename Playlist", isPresented: Binding(
                get: { renamingPlaylist != nil },
                set: { if !$0 { renamingPlaylist = nil } }
            )) {
                TextField("Playlist name", text: $renameText)
                Button("Cancel", role: .cancel) {
                    renamingPlaylist = nil
                }
                Button("Save") {
                    if let p = renamingPlaylist {
                        libraryVM.renamePlaylist(p, newName: renameText, context: modelContext)
                    }
                    renamingPlaylist = nil
                }
            } message: {
                Text("Update the name of your playlist.")
            }
        }
    }

    @ViewBuilder
    private func likedSongsSection() -> some View {
        if !likedSongs.isEmpty {
            Section {
                NavigationLink {
                    PlaylistDetailView(virtualName: "Liked Songs", virtualSongs: likedSongs)
                        .environmentObject(playerVM)
                        .environmentObject(theme)
                } label: {
                    HStack(spacing: 12) {
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .overlay(
                            Image(systemName: "heart.fill")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(.white)
                        )
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.smallCornerRadius, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Liked Songs")
                                .font(Constants.Typography.titleMedium)
                                .foregroundStyle(colors.textPrimary)
                            Text("\(likedSongs.count) songs • Playlist")
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
            } header: {
                Text("Playlists")
                    .font(Constants.Typography.titleLarge)
                    .foregroundStyle(colors.textPrimary)
            }
        }
    }

    @ViewBuilder
    private func playlistsSection() -> some View {
        if playlists.isEmpty {
            EmptyStateView(
                title: "It's quiet in here",
                subtitle: "Create your first playlist and fill it with vibes.",
                buttonTitle: "+ Create Playlist",
                onButtonTap: { showNewPlaylist = true }
            )
        } else {
            Section {
                ForEach(playlists) { playlist in
                    playlistRow(playlist)
                        .contextMenu {
                            Button("Rename") {
                                renamingPlaylist = playlist
                                renameText = playlist.name
                            }
                            Button(role: .destructive) {
                                playlistToDelete = playlist
                                showDeleteAlert = true
                            } label: {
                                Text("Delete Playlist")
                            }
                        }
                }
                .onDelete { indexSet in
                    if let index = indexSet.first {
                        playlistToDelete = playlists[index]
                        showDeleteAlert = true
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func topSongsSection() -> some View {
        if !topSongs.isEmpty {
            Section {
                ForEach(Array(topSongs.prefix(15)), id: \.id) { song in
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

    @ViewBuilder
    private func playlistRow(_ playlist: Playlist) -> some View {
        NavigationLink {
            PlaylistDetailView(playlist: playlist)
                .environmentObject(playerVM)
                .environmentObject(theme)
        } label: {
            HStack(spacing: 12) {
                playlistCover(for: playlist)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.smallCornerRadius, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(playlist.name)
                        .font(Constants.Typography.titleMedium)
                        .foregroundStyle(colors.textPrimary)
                    Text("\(playlist.songs.count) songs • Playlist")
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

    @ViewBuilder
    private func playlistCover(for playlist: Playlist) -> some View {
        let songs = playlist.songs
        if songs.count >= 4 {
            let first4 = Array(songs.prefix(4))
            GeometryReader { geo in
                let size = geo.size
                let halfW = size.width / 2
                let halfH = size.height / 2
                ZStack {
                    ForEach(0..<4, id: \.self) { index in
                        let song = first4[index]
                        AsyncImage(url: URL(string: song.artworkURL)) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().aspectRatio(contentMode: .fill)
                            default:
                                Rectangle().fill(colors.bgElevated)
                            }
                        }
                        .frame(width: halfW, height: halfH)
                        .clipped()
                        .position(x: (index % 2 == 0 ? halfW / 2 : 1.5 * halfW),
                                  y: (index / 2 == 0 ? halfH / 2 : 1.5 * halfH))
                    }
                }
            }
        } else if let first = songs.first {
            AsyncImage(url: URL(string: first.artworkURL)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    Rectangle().fill(colors.bgElevated)
                }
            }
        } else {
            LinearGradient(
                colors: [colors.primaryAccent, colors.bgElevated],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(
                Image(systemName: "music.note.list")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            )
        }
    }
}

#Preview {
    LibraryView()
        .environmentObject(PlayerViewModel.shared)
        .environmentObject(ThemeManager())
        .modelContainer(for: [Song.self, Playlist.self, ListeningHistory.self, UserPreferences.self], inMemory: true)
}
