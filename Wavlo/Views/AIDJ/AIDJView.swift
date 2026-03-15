import SwiftUI
import SwiftData

struct AIDJView: View {

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var playerVM: PlayerViewModel
    @EnvironmentObject private var theme: ThemeManager
    @StateObject private var viewModel = AIDJViewModel()

    private var colors: WavloColors { theme.colors }
    @Query private var prefs: [UserPreferences]
    @Query(sort: \ListeningHistory.playedAt, order: .reverse) private var history: [ListeningHistory]
    @Query(filter: #Predicate<Song> { $0.isLiked }) private var likedSongs: [Song]
    @Query(sort: \Song.playCount, order: .reverse) private var topSongs: [Song]

    private var userPrefs: UserPreferences? {
        prefs.first
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom top bar — title only, no back button (Wavlo DJ is a tab)
            HStack {
                Spacer()
                Text("Wavlo DJ")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(colors.textPrimary)
                Spacer()
            }
            .padding(.vertical, 12)
            .background(colors.bgPrimary)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { msg in
                            ChatBubbleView(message: msg)
                                .id(msg.id)
                        }
                        if viewModel.isSending {
                            HStack {
                                ProgressView()
                                    .tint(colors.primaryAccent)
                                Text("Wavlo DJ is thinking...")
                                    .font(Constants.Typography.bodySmall)
                                    .foregroundStyle(colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        if !viewModel.suggestedSongs.isEmpty {
                            Text("Suggested for you")
                                .font(Constants.Typography.titleMedium)
                                .foregroundStyle(colors.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 8)
                            ForEach(viewModel.suggestedSongs, id: \.id) { song in
                                SongSuggestionCardView(song: song) {
                                    playerVM.play(songs: viewModel.suggestedSongs, startIndex: viewModel.suggestedSongs.firstIndex(where: { $0.id == song.id }) ?? 0)
                                }
                            }
                        }
                    }
                    .wavloScreenPadding()
                    .padding(.vertical, 16)
                    .padding(.bottom, 80)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let last = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(Constants.Typography.caption)
                    .foregroundStyle(WavloColors.accentTeal)
                    .padding(.horizontal)
            }

            HStack(spacing: 8) {
                TextField("Ask Wavlo DJ...", text: $viewModel.inputText, axis: .vertical)
                    .font(Constants.Typography.bodyRegular)
                    .foregroundStyle(colors.textPrimary)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(colors.bgInput)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.pillCornerRadius, style: .continuous))
                    .onSubmit {
                        Task { await viewModel.sendMessage() }
                    }
                Button {
                    Task {
                        if viewModel.voiceService.isListening {
                            viewModel.stopListening()
                        } else {
                            await viewModel.startListening()
                        }
                    }
                } label: {
                    Image(systemName: viewModel.voiceService.isListening ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(viewModel.voiceService.isListening ? WavloColors.accentTeal : colors.primaryAccent)
                }
                Button {
                    Task { await viewModel.sendMessage() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(colors.primaryAccent)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(colors.bgCard)
        }
        .padding(.bottom, playerVM.currentSong != nil ? 70 : 0)
        .scrollContentBackground(.hidden)
        .background(colors.bgPrimary)
        .wavloKeyboardDismissToolbar()
        .onAppear {
            viewModel.geminiAPIKey = userPrefs?.geminiAPIKey ?? Constants.Gemini.defaultAPIKey
            viewModel.topGenres = userPrefs?.preferredGenres ?? []
            viewModel.recentSongs = history.prefix(5).compactMap { h in
                topSongs.first { $0.id == h.songID }.map { "\($0.title) by \($0.artistName)" }
            }
            viewModel.currentMood = userPrefs?.moodHistory.last ?? "chill"
            Task { await viewModel.requestAuthorization() }
        }
        .environmentObject(viewModel)
    }
}

#Preview {
    AIDJView()
        .environmentObject(PlayerViewModel.shared)
        .environmentObject(ThemeManager())
        .modelContainer(for: [Song.self, Playlist.self, ListeningHistory.self, UserPreferences.self], inMemory: true)
}
