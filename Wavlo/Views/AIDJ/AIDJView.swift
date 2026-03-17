import SwiftUI
import SwiftData
import UIKit

struct AIDJView: View {

    @Binding var selectedTab: Constants.Tab
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var playerVM: PlayerViewModel
    @EnvironmentObject private var theme: ThemeManager
    @StateObject private var viewModel = AIDJViewModel()
    @State private var isKeyboardVisible = false
    @State private var wasPlayingBeforeListening = false

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
            // Top bar: title centered; when keyboard is visible, show a glassy floating back button to go Home.
            HStack {
                if isKeyboardVisible {
                    Button {
                        dismissKeyboard()
                        selectedTab = .home
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 32, height: 32)
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(colors.textPrimary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                Text("Wavlo DJ")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(colors.textPrimary)
                Spacer()
                if isKeyboardVisible {
                    Color.clear
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [colors.bgPrimary.opacity(0.95), colors.bgPrimary.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

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

            if viewModel.voiceService.isListening {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                    Text("Listening...")
                        .font(Constants.Typography.caption)
                        .foregroundStyle(colors.textSecondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 2)
            }

            HStack(spacing: 8) {
                TextField("Ask Wavlo DJ...", text: $viewModel.inputText, axis: .vertical)
                    .font(Constants.Typography.bodyRegular)
                    .foregroundStyle(colors.textPrimary)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
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
                            // Stop recording: resume playback if it was playing and send message automatically.
                            viewModel.stopListening()
                            if wasPlayingBeforeListening {
                                playerVM.resumePlayback()
                                wasPlayingBeforeListening = false
                            }
                            let text = viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !text.isEmpty {
                                await viewModel.sendMessage()
                            }
                        } else {
                            // Start recording: remember current playback state and pause music.
                            wasPlayingBeforeListening = playerVM.isPlaying
                            if wasPlayingBeforeListening {
                                playerVM.pausePlayback()
                            }
                            await viewModel.startListening()
                        }
                    }
                } label: {
                    Image(systemName: viewModel.voiceService.isListening ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(viewModel.voiceService.isListening ? Color.red : colors.primaryAccent)
                        .scaleEffect(viewModel.voiceService.isListening ? 1.06 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.voiceService.isListening)
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
        // Mini player is hidden on the DJ tab, so don't reserve space for it.
        .padding(.bottom, 0)
        .scrollContentBackground(.hidden)
        .background(colors.bgPrimary)
        .wavloKeyboardDismissToolbar()
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
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
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    AIDJView(selectedTab: .constant(.aidj))
        .environmentObject(PlayerViewModel.shared)
        .environmentObject(ThemeManager())
        .modelContainer(for: [Song.self, Playlist.self, ListeningHistory.self, UserPreferences.self], inMemory: true)
}
