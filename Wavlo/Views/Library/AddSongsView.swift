import SwiftUI
import SwiftData

struct AddSongsView: View {

    @Bindable var playlist: Playlist
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var theme: ThemeManager
    @StateObject private var searchVM = SearchViewModel()
    @State private var searchText: String = ""

    private var colors: WavloColors { theme.colors }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                TextField("Search songs", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: searchText) { _, _ in
                        searchVM.searchText = searchText
                        searchVM.searchTextChanged()
                    }
                Button("Done") {
                    // Pop view
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
            .padding(.horizontal)

            List {
                ForEach(searchVM.searchResults, id: \.id) { song in
                    HStack {
                        SongRowView(song: song, onTap: {}, onLike: {})
                        Spacer()
                        if playlist.songs.contains(where: { $0.id == song.id }) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(WavloColors.accentGreen)
                        } else {
                            Button {
                                LibraryViewModel().addToPlaylist(song: song, playlist: playlist, context: modelContext)
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(colors.primaryAccent)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Add Songs")
        .navigationBarTitleDisplayMode(.inline)
        .background(colors.bgPrimary.ignoresSafeArea())
    }
}

