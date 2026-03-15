import SwiftUI

struct LyricsView: View {

    let lyrics: String
    let duration: Double
    let currentTime: Double
    let songTitle: String
    let artistName: String
    let albumName: String
    let artworkURL: String
    @EnvironmentObject private var theme: ThemeManager

    private var colors: WavloColors { theme.colors }

    private var lines: [String] {
        lyrics
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private var timePerLine: Double {
        guard !lines.isEmpty, duration > 0 else { return 1 }
        return duration / Double(lines.count)
    }

    private var activeIndex: Int {
        guard timePerLine > 0 else { return 0 }
        let idx = Int(currentTime / timePerLine)
        return min(max(0, idx), lines.count - 1)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    AsyncImage(url: URL(string: artworkURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius)
                                .fill(colors.bgElevated)
                        }
                    }
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius, style: .continuous))

                    VStack(spacing: 4) {
                        Text(songTitle)
                            .font(Constants.Typography.titleLarge)
                            .foregroundStyle(colors.textPrimary)
                            .lineLimit(1)
                        Text(artistName)
                            .font(Constants.Typography.bodyRegular)
                            .foregroundStyle(colors.textSecondary)
                        if !albumName.isEmpty {
                            Text(albumName)
                                .font(Constants.Typography.caption)
                                .foregroundStyle(colors.textMuted)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(colors.bgElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }

                    VStack(spacing: 16) {
                        ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                            let isActive = index == activeIndex
                            Text(line)
                                .font(isActive ? Constants.Typography.lyricsActive : Constants.Typography.lyricsInactive)
                                .foregroundStyle(colors.textPrimary.opacity(isActive ? 1 : 0.4))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .id(index)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.vertical, 24)
            }
            .onChange(of: activeIndex) { _, newIndex in
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
            .onAppear {
                proxy.scrollTo(activeIndex, anchor: .center)
            }
        }
    }
}

#Preview {
    LyricsView(
        lyrics: "Line one\nLine two\nLine three\nLine four",
        duration: 120,
        currentTime: 60,
        songTitle: "Song",
        artistName: "Artist",
        albumName: "Album",
        artworkURL: ""
    )
    .environmentObject(ThemeManager())
    .background(Color(hex: "0d0d0d"))
}
