import Foundation
import SwiftData
import os.log
import Combine

@MainActor
final class ListeningTracker: ObservableObject {

    private let logger = Logger(subsystem: "com.wavlo", category: "ListeningTracker")

    private let audioService: AudioPlayerService
    private let mlEngine: WavloMLEngine
    private let modelContext: ModelContext

    private var currentSong: Song?
    private var currentStartTime: Date?
    private var lastProgressRatio: Double = 0
    private var eventsSinceLastTrain: Int = 0

    init(audioService: AudioPlayerService = AudioPlayerService(),
         modelContext: ModelContext) {
        self.audioService = audioService
        self.modelContext = modelContext
        self.mlEngine = WavloMLEngine(modelContext: modelContext)
        bindAudioCallbacks()
    }

    private func bindAudioCallbacks() {
        audioService.onPlaybackProgress = { [weak self] current, duration in
            Task { @MainActor in
                guard let self else { return }
                let ratio = duration > 0 ? current / duration : 0
                self.updateProgress(ratio: ratio)
            }
        }
        audioService.onPlaybackFinished = { [weak self] songID in
            Task { @MainActor in
                guard let self else { return }
                if let id = songID {
                    self.songCompleted(for: id)
                }
            }
        }
    }

    // MARK: - Public API

    func startTracking(song: Song) {
        currentSong = song
        currentStartTime = Date()
        lastProgressRatio = 0
    }

    func updateProgress(ratio: Double) {
        lastProgressRatio = max(0.0, min(1.0, ratio))
    }

    func songCompleted() {
        guard let song = currentSong else { return }
        songCompleted(for: song.id)
    }

    func songSkipped() {
        guard let song = currentSong else { return }
        createHistoryEntry(for: song, completionRatio: lastProgressRatio, wasSkipped: true)
        currentSong = nil
        currentStartTime = nil
        triggerRetrainIfNeeded()
    }

    func getRecentHistory(limit: Int) -> [ListeningHistory] {
        let descriptor = FetchDescriptor<ListeningHistory>(sortBy: [SortDescriptor(\.playedAt, order: .reverse)])
        guard let result = try? modelContext.fetch(descriptor) else { return [] }
        return Array(result.prefix(limit))
    }

    // MARK: - Internals

    private func songCompleted(for songID: String) {
        guard let song = fetchSong(by: songID) else { return }
        createHistoryEntry(for: song, completionRatio: 1.0, wasSkipped: false)
        song.playCount += 1
        try? modelContext.save()
        currentSong = nil
        currentStartTime = nil
        triggerRetrainIfNeeded()
    }

    private func createHistoryEntry(for song: Song, completionRatio: Double, wasSkipped: Bool) {
        let entry = ListeningHistory(
            songID: song.id,
            playedAt: Date(),
            completionRatio: completionRatio,
            wasSkipped: wasSkipped,
            source: nil,
            genre: song.genre,
            artistName: song.artistName
        )
        modelContext.insert(entry)
        try? modelContext.save()
        eventsSinceLastTrain += 1
    }

    private func fetchSong(by id: String) -> Song? {
        let descriptor = FetchDescriptor<Song>(predicate: #Predicate { $0.id == id })
        return try? modelContext.fetch(descriptor).first
    }

    private func triggerRetrainIfNeeded() {
        guard eventsSinceLastTrain >= 10 else { return }
        eventsSinceLastTrain = 0

        Task.detached { [weak self] in
            guard let self else { return }
            await self.retrainIfNeeded()
        }
    }

    private func retrainIfNeeded() async {
        let songs = fetchAllSongs()
        let history = fetchAllHistory()
        let likedIDs = Set(songs.filter { $0.isLiked }.map { $0.id })
        await mlEngine.trainAllModels(songs: songs, history: history, likedSongIDs: likedIDs)
    }

    private func fetchAllSongs() -> [Song] {
        let descriptor = FetchDescriptor<Song>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func fetchAllHistory() -> [ListeningHistory] {
        let descriptor = FetchDescriptor<ListeningHistory>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}

