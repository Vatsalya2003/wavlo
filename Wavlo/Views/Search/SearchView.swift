import SwiftUI
import SwiftData

struct SearchView: View {

    @StateObject private var viewModel = SearchViewModel()
    @EnvironmentObject private var playerVM: PlayerViewModel
    @EnvironmentObject private var theme: ThemeManager
    @State private var selectedGenre = "All"

    private var colors: WavloColors { theme.colors }

    private var displayedSongs: [Song] {
        if selectedGenre == "All" {
            return viewModel.searchResults
        }
        return viewModel.genreTracks[selectedGenre] ?? []
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    GenreFilterView(selectedGenre: $selectedGenre)
                        .onChange(of: selectedGenre) { _, newValue in
                            if newValue != "All" {
                                Task { await viewModel.loadGenre(newValue) }
                            }
                        }

                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(colors.textMuted)
                        TextField("Artists, songs, or genres", text: $viewModel.searchText)
                            .font(Constants.Typography.bodyRegular)
                            .foregroundStyle(colors.textPrimary)
                            .submitLabel(.search)
                            .onChange(of: viewModel.searchText) { _, _ in
                                viewModel.searchTextChanged()
                            }
                            .onSubmit {
                                Task { await viewModel.performSearch() }
                            }
                    }
                    .padding(Constants.Layout.cardPadding)
                    .background(colors.bgInput)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.smallCornerRadius, style: .continuous))

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(Constants.Typography.bodySmall)
                            .foregroundStyle(WavloColors.accentTeal)
                    }

                    if viewModel.isLoading {
                        ProgressView()
                            .tint(WavloColors.accentGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                    } else if !displayedSongs.isEmpty {
                        Text(selectedGenre == "All" ? "Suggestions" : selectedGenre)
                            .font(Constants.Typography.titleMedium)
                            .foregroundStyle(colors.textPrimary)
                        LazyVStack(spacing: Constants.Layout.baseSpacing) {
                            ForEach(displayedSongs, id: \.id) { song in
                                SongRowView(
                                    song: song,
                                    onTap: {
                                        // Dismiss keyboard when user starts playback from search
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        if let idx = displayedSongs.firstIndex(where: { $0.id == song.id }) {
                                            playerVM.play(songs: displayedSongs, startIndex: idx)
                                        }
                                    },
                                    onLike: { playerVM.toggleLike(song) }
                                )
                            }
                        }
                    }

                    Text("Browse by genre")
                        .font(Constants.Typography.titleMedium)
                        .foregroundStyle(colors.textPrimary)
                        .padding(.top, 8)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(Constants.genres.prefix(8), id: \.name) { g in
                            NavigationLink {
                                GenreBrowseView(genre: g.name)
                                    .environmentObject(playerVM)
                                    .environmentObject(theme)
                            } label: {
                                VibeCardView(
                                    title: g.name,
                                    subtitle: "Explore",
                                    imageURL: nil,
                                    accentColor: Color(hex: g.color)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .wavloScreenPadding()
                .padding(.bottom, playerVM.currentSong != nil ? 170 : 100)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)
            .background(colors.bgPrimary)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    SearchView()
        .environmentObject(PlayerViewModel.shared)
        .environmentObject(ThemeManager())
}
