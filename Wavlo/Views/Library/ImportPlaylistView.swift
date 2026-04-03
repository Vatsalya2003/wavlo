import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportPlaylistView: View {

    @StateObject private var viewModel = ImportPlaylistViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss
    @EnvironmentObject private var theme:    ThemeManager
    @EnvironmentObject private var playerVM: PlayerViewModel

    private var colors: WavloColors { theme.colors }

    var body: some View {
        NavigationStack {
            ZStack {
                colors.bgPrimary.ignoresSafeArea()

                switch viewModel.importState {
                case .idle:
                    idleView
                case .parsing, .matching:
                    loadingView
                case .done:
                    resultsView
                case .error:
                    errorView
                }
            }
            .navigationTitle("Import from Spotify")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(colors.textSecondary)
                }
            }
        }
        .fileImporter(
            isPresented: $viewModel.isShowingFilePicker,
            allowedContentTypes: [.commaSeparatedText],
            onCompletion: { result in
                switch result {
                case .success(let url):
                    viewModel.handleFileSelection(url: url)
                case .failure(let error):
                    viewModel.errorMessage = error.localizedDescription
                    viewModel.importState  = .error
                }
            }
        )
    }

    // MARK: - Idle

    private var idleView: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "square.and.arrow.down.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(colors.primaryAccent)

                Text("Import from Spotify")
                    .font(Constants.Typography.displayMedium)
                    .foregroundStyle(colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Export your Spotify playlist using Exportify, then import the CSV here.")
                    .font(Constants.Typography.bodyRegular)
                    .foregroundStyle(colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Spacer()

            Button {
                viewModel.isShowingFilePicker = true
            } label: {
                Label("Choose CSV File", systemImage: "doc.text")
                    .font(Constants.Typography.pill)
                    .foregroundStyle(colors.bgPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(colors.primaryAccent)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, Constants.Layout.screenPadding)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.4)
                .tint(colors.primaryAccent)

            Text(viewModel.progressLabel)
                .font(Constants.Typography.bodyLarge)
                .foregroundStyle(colors.textSecondary)
                .multilineTextAlignment(.center)

            ProgressView(value: viewModel.progress)
                .progressViewStyle(.linear)
                .tint(colors.primaryAccent)
                .padding(.horizontal, Constants.Layout.screenPadding)
                .animation(.easeInOut(duration: 0.3), value: viewModel.progress)

            Spacer()
        }
    }

    // MARK: - Results

    private var resultsView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Matched songs
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Matched — \(viewModel.matchedSongs.count) songs")
                            .font(Constants.Typography.titleLarge)
                            .foregroundStyle(colors.textPrimary)

                        if viewModel.matchedSongs.isEmpty {
                            Text("No songs were found on JioSaavn.")
                                .font(Constants.Typography.bodyRegular)
                                .foregroundStyle(colors.textMuted)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(viewModel.matchedSongs, id: \.id) { song in
                                SongRowView(song: song, onTap: {}, onLike: {})
                            }
                        }
                    }

                    // Unmatched songs
                    if !viewModel.unmatchedRows.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Not Found — \(viewModel.unmatchedRows.count) songs")
                                .font(Constants.Typography.titleLarge)
                                .foregroundStyle(colors.textPrimary)

                            ForEach(viewModel.unmatchedRows.indices, id: \.self) { i in
                                unmatchedRow(viewModel.unmatchedRows[i])
                            }
                        }
                    }
                }
                .wavloScreenPadding()
                .padding(.vertical, 20)
                .padding(.bottom, 200)
            }

            // Sticky save footer
            saveFooter
        }
    }

    @ViewBuilder
    private func unmatchedRow(_ row: SpotifyCSVRow) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: Constants.Layout.songRowCornerRadius, style: .continuous)
                .fill(colors.bgElevated)
                .frame(width: Constants.Layout.songRowArtworkSize,
                       height: Constants.Layout.songRowArtworkSize)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 18))
                        .foregroundStyle(colors.textMuted)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(row.trackName)
                    .font(Constants.Typography.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundStyle(colors.textMuted)
                    .lineLimit(1)
                Text(row.artistName)
                    .font(Constants.Typography.bodySmall)
                    .foregroundStyle(colors.textMuted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(minHeight: 64)
        .background(colors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius, style: .continuous))
    }

    private var saveFooter: some View {
        VStack(spacing: 12) {
            TextField("Playlist name", text: $viewModel.playlistName)
                .font(Constants.Typography.bodyLarge)
                .foregroundStyle(colors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(colors.bgInput)
                .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius, style: .continuous))
                .wavloKeyboardDismissToolbar()

            Button {
                _ = viewModel.savePlaylist(context: modelContext)
                dismiss()
            } label: {
                Text("Save Playlist")
                    .font(Constants.Typography.pill)
                    .foregroundStyle(colors.bgPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.matchedSongs.isEmpty ? colors.textMuted : colors.primaryAccent)
                    .clipShape(Capsule())
            }
            .disabled(viewModel.matchedSongs.isEmpty)

            Button("Cancel") { dismiss() }
                .font(Constants.Typography.bodyLarge)
                .foregroundStyle(colors.textSecondary)
        }
        .padding(.horizontal, Constants.Layout.screenPadding)
        .padding(.vertical, 16)
        .background(
            colors.bgCard
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: .black.opacity(0.15), radius: 12, y: -4)
        )
    }

    // MARK: - Error

    private var errorView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.orange)

            Text(viewModel.errorMessage ?? "Something went wrong.")
                .font(Constants.Typography.bodyRegular)
                .foregroundStyle(colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                viewModel.reset()
            } label: {
                Text("Try Again")
                    .font(Constants.Typography.pill)
                    .foregroundStyle(colors.bgPrimary)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(colors.primaryAccent)
                    .clipShape(Capsule())
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    ImportPlaylistView()
        .environmentObject(ThemeManager())
        .environmentObject(PlayerViewModel.shared)
        .modelContainer(
            for: [Song.self, Playlist.self, ListeningHistory.self, UserPreferences.self],
            inMemory: true
        )
}
