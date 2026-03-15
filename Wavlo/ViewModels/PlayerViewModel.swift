import Foundation
import SwiftUI
import SwiftData
import os.log
import Combine

@MainActor
final class PlayerViewModel: ObservableObject {

    static let shared = PlayerViewModel()

    private let audioService = AudioPlayerService()
    private let logger = Logger(subsystem: "com.wavlo", category: "PlayerVM")

    @Published var currentSong: Song?
    @Published var queue: [Song] = []
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isPlaying = false
    @Published var isPresentingFullPlayer = false

    private var modelContext: ModelContext?

    private init() {
        Task {
            await bindAudioService()
        }
    }

    func setModelContext(_ context: ModelContext) {
        modelContext = context
    }

    private func bindAudioService() async {
        await audioService.onPlaybackProgress = { [weak self] current, dur in
            Task { @MainActor in
                self?.currentTime = current
                self?.duration = dur
            }
        }
        await audioService.onCurrentItemChanged = { [weak self] songID in
            Task { @MainActor in
                self?.updateCurrentSong(by: songID)
            }
        }
    }

    private func updateCurrentSong(by id: String?) {
        guard let id = id else {
            currentSong = nil
            return
        }
        currentSong = queue.first { $0.id == id }
    }

    func play(songs: [Song], startIndex: Int = 0) {
        guard !songs.isEmpty, startIndex < songs.count else { return }
        ensureSongsInContext(songs)
        queue = songs
        let urls = songs.compactMap { URL(string: $0.streamURL) }
        let ids = songs.map(\.id)
        Task {
            await audioService.replaceQueue(with: urls, startIndex: startIndex, songIDs: ids)
            await MainActor.run {
                currentSong = songs[startIndex]
                recordPlayStart(song: songs[startIndex])
            }
            await audioService.play()
            await MainActor.run { isPlaying = true }
        }
    }

    private func ensureSongsInContext(_ songs: [Song]) {
        guard let ctx = modelContext else { return }
        for song in songs {
            if song.modelContext == nil {
                ctx.insert(song)
            }
        }
        try? modelContext?.save()
    }

    func togglePlayPause() {
        Task {
            await audioService.togglePlayPause()
            let playing = await audioService.isPlaying
            await MainActor.run {
                isPlaying = playing
            }
        }
    }

    func skipToNext() {
        Task {
            await audioService.skipToNext()
        }
    }

    func skipToPrevious() {
        Task {
            await audioService.skipToPrevious()
        }
    }

    func seek(to progress: Double) {
        let time = progress * duration
        Task {
            await audioService.seek(to: time)
            await MainActor.run { currentTime = time }
        }
    }

    func recordPlayStart(song: Song) {
        modelContext?.insert(ListeningHistory(songID: song.id, playedAt: Date(), completionRatio: 0, wasSkipped: false))
        song.playCount += 1
        try? modelContext?.save()
    }

    func recordPlayEnd(songID: String, completionRatio: Double, wasSkipped: Bool) {
        let entry = ListeningHistory(songID: songID, playedAt: Date(), completionRatio: completionRatio, wasSkipped: wasSkipped)
        modelContext?.insert(entry)
        try? modelContext?.save()
    }

    func toggleLike(_ song: Song) {
        if song.modelContext == nil, let ctx = modelContext {
            ctx.insert(song)
        }
        song.isLiked.toggle()
        try? modelContext?.save()
    }
}
