import SwiftUI
import SwiftData

struct GenreBrowseView: View {

    let genre: String
    @StateObject private var viewModel = SearchViewModel()
    @EnvironmentObject private var playerVM: PlayerViewModel
    @EnvironmentObject private var theme: ThemeManager

    private var colors: WavloColors { theme.colors }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Constants.Layout.baseSpacing) {
                ForEach(viewModel.genreTracks[genre] ?? [], id: \.id) { song in
                    SongRowView(
                        song: song,
                        onTap: {
                            let list = viewModel.genreTracks[genre] ?? []
                            if let idx = list.firstIndex(where: { $0.id == song.id }) {
                                playerVM.play(songs: list, startIndex: idx)
                            }
                        },
                        onLike: { playerVM.toggleLike(song) }
                    )
                }
            }
            .wavloScreenPadding()
            .padding(.bottom, 100)
        }
        .scrollContentBackground(.hidden)
        .background(colors.bgPrimary)
        .navigationTitle(genre)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task { await viewModel.loadGenre(genre) }
        }
    }
}

#Preview {
    NavigationStack {
        GenreBrowseView(genre: "Pop")
            .environmentObject(PlayerViewModel.shared)
            .environmentObject(ThemeManager())
    }
}
