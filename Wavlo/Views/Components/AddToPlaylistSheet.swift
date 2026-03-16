import SwiftUI
import SwiftData

struct AddToPlaylistSheet: View {

    let song: Song
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var theme: ThemeManager
    @Query(sort: \Playlist.createdAt, order: .reverse) private var playlists: [Playlist]
    @StateObject private var libraryVM = LibraryViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var newPlaylistName: String = ""
    @State private var showNewPlaylistField = false

    private var colors: WavloColors { theme.colors }

    var body: some View {
        NavigationStack {
            List {
                if showNewPlaylistField {
                    Section("Create New Playlist") {
                        HStack {
                            TextField("Playlist name", text: $newPlaylistName)
                            Button("Create") {
                                guard !newPlaylistName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                                let playlist = libraryVM.createPlaylist(name: newPlaylistName, context: modelContext)
                                libraryVM.addToPlaylist(song: song, playlist: playlist, context: modelContext)
                                dismiss()
                            }
                        }
                    }
                } else {
                    Button {
                        showNewPlaylistField = true
                    } label: {
                        Label("Create New Playlist", systemImage: "plus.circle")
                    }
                }

                Section("Your Playlists") {
                    if playlists.isEmpty {
                        Text("No playlists yet. Create one to save this song.")
                            .foregroundStyle(colors.textSecondary)
                    } else {
                        ForEach(playlists) { playlist in
                            Button {
                                libraryVM.addToPlaylist(song: song, playlist: playlist, context: modelContext)
                                dismiss()
                            } label: {
                                HStack {
                                    Text(playlist.name)
                                    Spacer()
                                    if playlist.songs.contains(where: { $0.id == song.id }) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(WavloColors.accentGreen)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add to Playlist")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

