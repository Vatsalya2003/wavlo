import SwiftUI
import SwiftData

struct PlaylistDetailView: View {

    var playlist: Playlist?
    /// For virtual playlists like \"Liked Songs\" that are not backed by Playlist model.
    let virtualName: String?
    let virtualSongs: [Song]?
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var playerVM: PlayerViewModel
    @EnvironmentObject private var theme: ThemeManager
    @StateObject private var libraryVM = LibraryViewModel()
    @State private var isEditingOrder = false

    private var colors: WavloColors { theme.colors }

    init(playlist: Playlist) {
        self.playlist = playlist
        self.virtualName = nil
        self.virtualSongs = nil
    }

    init(virtualName: String, virtualSongs: [Song]) {
        self.playlist = nil
        self.virtualName = virtualName
        self.virtualSongs = virtualSongs
    }

    private var title: String {
        virtualName ?? playlist?.name ?? "Playlist"
    }

    private var songs: [Song] {
        if let virtualSongs { return virtualSongs }
        return playlist?.songs ?? []
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    coverView
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius, style: .continuous))
                    VStack(spacing: 4) {
                        Text(title)
                            .font(Constants.Typography.titleLarge)
                            .foregroundStyle(colors.textPrimary)
                        Text("\(songs.count) songs")
                            .font(Constants.Typography.bodyRegular)
                            .foregroundStyle(colors.textSecondary)
                    }
                    HStack(spacing: 16) {
                        Button {
                            guard !songs.isEmpty else { return }
                            playerVM.play(songs: songs, startIndex: 0, source: "playlist")
                        } label: {
                            Text("▶ Play All")
                                .font(Constants.Typography.bodyLarge)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(WavloColors.accentGreen)
                                .clipShape(Capsule())
                        }
                        Button {
                            guard !songs.isEmpty else { return }
                            let shuffled = songs.shuffled()
                            playerVM.play(songs: shuffled, startIndex: 0, source: "playlist")
                        } label: {
                            Text("🔀 Shuffle")
                                .font(Constants.Typography.bodyLarge)
                                .foregroundStyle(colors.primaryAccent)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 9)
                                .overlay(
                                    Capsule()
                                        .stroke(colors.primaryAccent, lineWidth: 1)
                                )
                        }
                    }
                    .padding(.top, 4)
                }
                .listRowBackground(colors.bgPrimary)
            }

            Section {
                if songs.isEmpty {
                    VStack(spacing: 8) {
                        Text("No songs yet. Search for music and add it here.")
                            .font(Constants.Typography.bodyRegular)
                            .foregroundStyle(colors.textSecondary)
                            .multilineTextAlignment(.center)
                        if playlist != nil {
                            NavigationLink {
                                AddSongsView(playlist: playlist!)
                            } label: {
                                Text("+ Add Songs")
                                    .font(Constants.Typography.bodyLarge)
                                    .foregroundStyle(WavloColors.accentGreen)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
                    .listRowBackground(colors.bgPrimary)
                } else {
                    ForEach(Array(songs.enumerated()), id: \.element.id) { index, song in
                        HStack {
                            SongRowView(
                                song: song,
                                onTap: {
                                    playerVM.play(songs: songs, startIndex: index, source: "playlist")
                                },
                                onLike: { playerVM.toggleLike(song) }
                            )
                        }
                        .swipeActions {
                            if let p = playlist {
                                Button(role: .destructive) {
                                    libraryVM.removeFromPlaylist(song: song, playlist: p, context: modelContext)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .onMove { indices, newOffset in
                        guard let p = playlist else { return }
                        libraryVM.moveSongs(in: p, from: indices, to: newOffset, context: modelContext)
                    }

                    if playlist != nil {
                        NavigationLink {
                            AddSongsView(playlist: playlist!)
                        } label: {
                            Text("+ Add Songs")
                                .font(Constants.Typography.bodyLarge)
                                .foregroundStyle(WavloColors.accentGreen)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .listRowBackground(colors.bgPrimary)
                    }
                }
            }
            .listRowBackground(colors.bgPrimary)
        }
        .environment(\.editMode, .constant(isEditingOrder ? .active : .inactive))
        .scrollContentBackground(.hidden)
        .background(colors.bgPrimary)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if playlist != nil && !songs.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditingOrder ? "Done" : "Edit") {
                        isEditingOrder.toggle()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var coverView: some View {
        if let p = playlist, !p.songs.isEmpty {
            // Reuse same cover logic as LibraryView
            ZStack {
                LinearGradient(
                    colors: [colors.bgElevated, colors.bgPrimary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                if let first = p.songs.first {
                    AsyncImage(url: URL(string: first.artworkURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                        default:
                            Color.clear
                        }
                    }
                    .opacity(0.9)
                }
            }
        } else if let virtualSongs, let first = virtualSongs.first {
            AsyncImage(url: URL(string: first.artworkURL)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius)
                        .fill(colors.bgElevated)
                }
            }
        } else {
            RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius)
                .fill(colors.bgElevated)
        }
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

