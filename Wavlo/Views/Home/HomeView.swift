import SwiftUI
import SwiftData

struct HomeView: View {

    @StateObject private var viewModel = HomeViewModel()
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var playerVM: PlayerViewModel
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var showSettings = false
    @State private var filterPill = "All"

    @Query(sort: \ListeningHistory.playedAt, order: .reverse) private var history: [ListeningHistory]
    @Query private var allSongs: [Song]

    private var colors: WavloColors { theme.colors }

    private var recentSongs: [Song] {
        var seen = Set<String>()
        return history.compactMap { h in
            guard !seen.contains(h.songID) else { return nil }
            seen.insert(h.songID)
            return allSongs.first { $0.id == h.songID }
        }
        .prefix(15)
        .map { $0 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                topBar

                if !recentSongs.isEmpty {
                    HomeSectionView(title: "Jump back in") {
                        ForEach(recentSongs, id: \.id) { song in
                            PlaylistCardView(
                                imageURL: song.artworkURL.isEmpty ? nil : song.artworkURL,
                                title: song.title,
                                subtitle: song.artistName,
                                onTap: {
                                    playerVM.play(songs: Array(recentSongs), startIndex: recentSongs.firstIndex(where: { $0.id == song.id }) ?? 0)
                                }
                            )
                        }
                    }
                }

                ForEach(Array(viewModel.homeModules.enumerated()), id: \.offset) { _, module in
                    let sectionTitle = module.title ?? "Section"
                    let items = module.data ?? []
                    if !items.isEmpty {
                        HomeSectionView(title: sectionTitle) {
                            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                                let songs = item.songsOrResults?.map { $0.toSong() } ?? []
                                PlaylistCardView(
                                    imageURL: item.image,
                                    title: item.title ?? "Untitled",
                                    subtitle: item.subtitle,
                                    onTap: {
                                        if !songs.isEmpty {
                                            playerVM.play(songs: songs, startIndex: 0)
                                        }
                                    }
                                )
                            }
                        }
                    }
                }

                if viewModel.errorMessage != nil {
                    Text(viewModel.errorMessage ?? "")
                        .font(Constants.Typography.bodySmall)
                        .foregroundStyle(WavloColors.accentTeal)
                }

                if viewModel.isLoading && viewModel.homeModules.isEmpty {
                    ProgressView()
                        .tint(colors.primaryAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                }

                moodVibesSection

                if !viewModel.moodTracks.isEmpty {
                    HomeSectionView(title: "\(viewModel.selectedMood.capitalized) mix") {
                        ForEach(viewModel.moodTracks, id: \.id) { song in
                            PlaylistCardView(
                                imageURL: song.artworkURL.isEmpty ? nil : song.artworkURL,
                                title: song.title,
                                subtitle: song.artistName,
                                onTap: {
                                    playerVM.play(songs: viewModel.moodTracks, startIndex: viewModel.moodTracks.firstIndex(where: { $0.id == song.id }) ?? 0)
                                }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, playerVM.currentSong != nil ? 170 : 100)
        }
        .scrollContentBackground(.hidden)
        .background(colors.bgPrimary)
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
            }
            .environmentObject(theme)
        }
        .onAppear {
            Task {
                await viewModel.loadHomeData()
                await viewModel.loadTracksForMood(viewModel.selectedMood)
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                showSettings = true
            } label: {
                if let url = authVM.profilePhotoURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                        default:
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundStyle(colors.textSecondary)
                        }
                    }
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 36, height: 36)
                        .foregroundStyle(colors.textSecondary)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterPill(title: "All", isSelected: filterPill == "All") { filterPill = "All" }
                    FilterPill(title: "Music", isSelected: filterPill == "Music") { filterPill = "Music" }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var moodVibesSection: some View {
        VStack(alignment: .leading, spacing: Constants.Layout.baseSpacing) {
            Text("Mood Vibes")
                .font(Constants.Typography.titleLarge)
                .fontWeight(.bold)
                .foregroundStyle(colors.textPrimary)

            MoodSelectorView(selectedMood: $viewModel.selectedMood) { mood in
                Task { await viewModel.loadTracksForMood(mood) }
            }
        }
    }
}

private struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject private var theme: ThemeManager
    private var colors: WavloColors { theme.colors }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Constants.Typography.pill)
                .foregroundStyle(isSelected ? colors.bgPrimary : colors.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isSelected ? colors.primaryAccent : colors.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.pillCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
        .environmentObject(PlayerViewModel.shared)
        .environmentObject(ThemeManager())
        .modelContainer(for: [Song.self, Playlist.self, ListeningHistory.self, UserPreferences.self], inMemory: true)
}
