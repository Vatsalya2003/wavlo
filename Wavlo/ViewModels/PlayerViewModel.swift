import Foundation
import SwiftUI
import SwiftData
import os.log
import Combine
import MediaPlayer
import UIKit
import AVFoundation

@MainActor
final class PlayerViewModel: ObservableObject {

    static let shared = PlayerViewModel()

    private let audioService = AudioPlayerService()
    private let autoQueueManager = AutoQueueManager()
    private let logger = Logger(subsystem: "com.wavlo", category: "PlayerVM")

    @Published var currentSong: Song?
    @Published var queue: [Song] = []
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isPlaying = false
    @Published var isPresentingFullPlayer = false

    struct OutputDeviceInfo: Equatable {
        let name: String
        let iconSystemName: String
    }

    /// Non-nil only when output is Bluetooth/AirPlay (speaker/receiver shows nil).
    @Published var currentOutputDevice: OutputDeviceInfo?
    @Published var isShuffleOn = false
    @Published var isRepeatOn = false
    @Published var isSleepTimerOn = false

    private var modelContext: ModelContext?
    /// Song IDs already played this session (no repeats in recommendations).
    private var playedInSessionIDs: Set<String> = []

    // Lock screen / Control Center
    private let nowPlayingCenter = MPNowPlayingInfoCenter.default()
    private let commandCenter = MPRemoteCommandCenter.shared()
    private let artworkCache = NSCache<NSString, UIImage>()
    private var lastElapsedUpdate: TimeInterval = 0
    private var routeObserver: NSObjectProtocol?

    private init() {
        Task {
            await bindAudioService()
        }
        configureRemoteCommands()
        startObservingAudioRoute()
    }

    func setModelContext(_ context: ModelContext) {
        modelContext = context
    }

    private func startObservingAudioRoute() {
        refreshOutputDevice()
        routeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshOutputDevice()
        }
    }

    private func refreshOutputDevice() {
        let session = AVAudioSession.sharedInstance()
        guard let output = session.currentRoute.outputs.first else {
            currentOutputDevice = nil
            return
        }
        switch output.portType {
        case .bluetoothA2DP, .bluetoothHFP, .bluetoothLE:
            currentOutputDevice = OutputDeviceInfo(name: output.portName, iconSystemName: "bluetooth")
        case .airPlay:
            currentOutputDevice = OutputDeviceInfo(name: output.portName, iconSystemName: "airplayaudio")
        case .builtInSpeaker, .builtInReceiver:
            currentOutputDevice = nil
        default:
            currentOutputDevice = nil
        }
    }

    private func bindAudioService() async {
        await audioService.onPlaybackProgress = { [weak self] current, dur in
            Task { @MainActor in
                self?.currentTime = current
                self?.duration = dur
                self?.updateNowPlayingElapsedIfNeeded(currentTime: current, duration: dur)
            }
        }
        await audioService.onCurrentItemChanged = { [weak self] songID in
            Task { @MainActor in
                self?.updateCurrentSong(by: songID)
                self?.updateNowPlayingForCurrentSong()
            }
        }
        await audioService.onPlaybackFinished = { [weak self] finishedID in
            Task { @MainActor in
                self?.handlePlaybackFinished(finishedSongID: finishedID)
            }
        }
        await audioService.onIsPlayingChanged = { [weak self] playing in
            Task { @MainActor in
                self?.isPlaying = playing
                self?.updateNowPlayingPlaybackState()
            }
        }
    }

    private func handlePlaybackFinished(finishedSongID: String?) {
        guard let id = finishedSongID else { return }
        playedInSessionIDs.insert(id)
        let song = queue.first { $0.id == id }
        let ratio = song != nil && song!.duration > 0 ? min(1.0, duration / Double(song!.duration)) : 1.0
        recordPlayEnd(songID: id, completionRatio: ratio, wasSkipped: false, genre: song?.genre, artistName: song?.artistName, source: nil)
        let seedSong = song ?? queue.first { $0.id == id }
        if let seed = seedSong ?? currentSong {
            let stats = buildUserListeningStats()
            autoQueueManager.refillIfNeeded(
                seedSong: seed,
                queueCount: queue.count,
                existingQueue: queue,
                userStats: stats,
                useGemini: true
            ) { [weak self] newSongs in
                self?.appendSongsToQueue(newSongs)
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

    /// Songs after the current one in the queue (for "Up Next").
    var upNextSongs: [Song] {
        guard let current = currentSong, let idx = queue.firstIndex(where: { $0.id == current.id }) else {
            return Array(queue.dropFirst())
        }
        return Array(queue.suffix(from: idx + 1))
    }

    /// Play from a given queue index (e.g. tap on Up Next item).
    func playFromQueueIndex(_ index: Int) {
        guard index >= 0, index < queue.count else { return }
        let from = queue[index]
        let startIndex = queue.firstIndex(where: { $0.id == from.id }) ?? 0
        play(songs: queue, startIndex: startIndex, source: "queue")
    }

    /// Convenience overload for existing call sites that don't care about source.
    func play(songs: [Song], startIndex: Int = 0) {
        play(songs: songs, startIndex: startIndex, source: nil)
    }

    func play(songs: [Song], startIndex: Int = 0, source: String? = nil) {
        guard !songs.isEmpty, startIndex < songs.count else { return }
        playedInSessionIDs.removeAll()
        ensureSongsInContext(songs)
        queue = songs
        let urls = songs.compactMap { URL(string: $0.streamURL) }
        let ids = songs.map(\.id)
        Task {
            await audioService.replaceQueue(with: urls, startIndex: startIndex, songIDs: ids)
            await MainActor.run {
                currentSong = songs[startIndex]
                recordPlayStart(song: songs[startIndex], source: source)
            }
            await audioService.play()
            await MainActor.run { isPlaying = true }
            await MainActor.run {
                let stats = buildUserListeningStats()
                autoQueueManager.refillIfNeeded(
                    seedSong: songs[startIndex],
                    queueCount: queue.count,
                    existingQueue: queue,
                    userStats: stats,
                    useGemini: true
                ) { [weak self] newSongs in
                    self?.appendSongsToQueue(newSongs)
                }
            }
        }
    }

    func appendSongsToQueue(_ songs: [Song]) {
        guard !songs.isEmpty else { return }
        ensureSongsInContext(songs)
        queue.append(contentsOf: songs)
        let urls = songs.compactMap { URL(string: $0.streamURL) }
        let ids = songs.map(\.id)
        Task {
            await audioService.appendToQueue(urls: urls, songIDs: ids)
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
                updateNowPlayingPlaybackState()
            }
        }
    }

    func skipToNext() {
        if let song = currentSong {
            let ratio = duration > 0 ? min(1.0, currentTime / duration) : 0
            playedInSessionIDs.insert(song.id)
            recordPlayEnd(songID: song.id, completionRatio: ratio, wasSkipped: true, genre: song.genre, artistName: song.artistName, source: nil)
        }
        Task {
            await audioService.skipToNext()
        }
    }

    /// Remove songs from the queue at given offsets (used by Up Next UI). Keeps current song and rebuilds player queue.
    func removeFromQueue(at offsets: IndexSet) {
        guard let current = currentSong else { return }
        var newQueue = queue
        newQueue.remove(atOffsets: offsets)
        guard let newCurrentIndex = newQueue.firstIndex(where: { $0.id == current.id }) else {
            // If current song was removed, just update queue and stop auto-queue; next play() will rebuild.
            queue = newQueue
            return
        }
        queue = newQueue
        let urls = newQueue.compactMap { URL(string: $0.streamURL) }
        let ids = newQueue.map(\.id)
        Task {
            await audioService.replaceQueue(with: urls, startIndex: newCurrentIndex, songIDs: ids)
            await MainActor.run {
                currentSong = newQueue[newCurrentIndex]
            }
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
            await MainActor.run {
                updateNowPlayingElapsed(force: true)
            }
        }
    }

    func seekToSeconds(_ seconds: Double) {
        Task {
            await audioService.seek(to: seconds)
            await MainActor.run {
                currentTime = seconds
                updateNowPlayingElapsed(force: true)
            }
        }
    }

    func resumePlayback() {
        Task {
            await audioService.play()
            let playing = await audioService.isPlaying
            await MainActor.run {
                isPlaying = playing
                updateNowPlayingPlaybackState()
            }
        }
    }

    func pausePlayback() {
        Task {
            await audioService.pause()
            let playing = await audioService.isPlaying
            await MainActor.run {
                isPlaying = playing
                updateNowPlayingPlaybackState()
            }
        }
    }

    func recordPlayStart(song: Song, source: String? = nil) {
        modelContext?.insert(ListeningHistory(songID: song.id, playedAt: Date(), completionRatio: 0, wasSkipped: false, source: source, genre: song.genre, artistName: song.artistName))
        song.playCount += 1
        try? modelContext?.save()
    }

    func recordPlayEnd(songID: String, completionRatio: Double, wasSkipped: Bool, genre: String? = nil, artistName: String? = nil, source: String? = nil) {
        let entry = ListeningHistory(songID: songID, playedAt: Date(), completionRatio: completionRatio, wasSkipped: wasSkipped, source: source, genre: genre, artistName: artistName)
        modelContext?.insert(entry)
        try? modelContext?.save()
    }

    private func buildUserListeningStats() -> UserListeningStats {
        var stats = UserListeningStats()
        stats.playedInSessionIDs = playedInSessionIDs
        guard let ctx = modelContext else { return stats }
        let descriptor = FetchDescriptor<ListeningHistory>(sortBy: [SortDescriptor(\.playedAt, order: .reverse)])
        guard let all = try? ctx.fetch(descriptor) else { return stats }
        let recent = Array(all.prefix(200))
        stats.skippedSongIDs = Set(recent.filter(\.wasSkipped).map(\.songID))
        let completed = recent.filter { !$0.wasSkipped && $0.completionRatio > 0.3 }
        var genreCounts: [String: Int] = [:]
        var artistCounts: [String: Int] = [:]
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        for h in completed {
            if let g = h.genre, !g.isEmpty {
                genreCounts[g, default: 0] += 1
            }
            if let a = h.artistName, !a.isEmpty {
                artistCounts[a, default: 0] += 1
                if h.playedAt >= sevenDaysAgo {
                    stats.recentArtistNames.insert(a)
                }
            }
        }
        stats.topGenreNames = genreCounts.sorted { $0.value > $1.value }.prefix(10).map(\.key)
        stats.topArtistNames = artistCounts.sorted { $0.value > $1.value }.prefix(15).map(\.key)
        for g in stats.topGenreNames where !g.isEmpty {
            stats.likedGenreNames.insert(g)
        }
        return stats
    }

    func toggleLike(_ song: Song) {
        if song.modelContext == nil, let ctx = modelContext {
            ctx.insert(song)
        }
        song.isLiked.toggle()
        try? modelContext?.save()
    }

    // MARK: - Lock Screen / Control Center

    private func configureRemoteCommands() {
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.isEnabled = true

        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.resumePlayback()
            return .success
        }
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.pausePlayback()
            return .success
        }
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.togglePlayPause()
            return .success
        }
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.skipToNext()
            return .success
        }
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.skipToPrevious()
            return .success
        }
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self, let e = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self.seekToSeconds(e.positionTime)
            return .success
        }
    }

    private func updateNowPlayingForCurrentSong() {
        guard let song = currentSong else {
            nowPlayingCenter.nowPlayingInfo = nil
            return
        }

        var info = nowPlayingCenter.nowPlayingInfo ?? [:]
        info[MPMediaItemPropertyTitle] = song.title
        info[MPMediaItemPropertyArtist] = song.artistName
        info[MPMediaItemPropertyAlbumTitle] = song.albumName
        info[MPMediaItemPropertyPlaybackDuration] = Double(song.duration)
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        nowPlayingCenter.nowPlayingInfo = info

        // Artwork: set asynchronously (don’t block metadata)
        let urlString = song.artworkURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: urlString), !urlString.isEmpty else { return }

        if let cached = artworkCache.object(forKey: urlString as NSString) {
            setNowPlayingArtwork(image: cached)
            return
        }

        Task.detached { [weak self] in
            guard let self else { return }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let img = UIImage(data: data) {
                    self.artworkCache.setObject(img, forKey: urlString as NSString)
                    await MainActor.run {
                        self.setNowPlayingArtwork(image: img)
                    }
                }
            } catch { }
        }
    }

    private func setNowPlayingArtwork(image: UIImage) {
        var info = nowPlayingCenter.nowPlayingInfo ?? [:]
        let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        info[MPMediaItemPropertyArtwork] = artwork
        nowPlayingCenter.nowPlayingInfo = info
    }

    private func updateNowPlayingPlaybackState() {
        guard currentSong != nil else { return }
        var info = nowPlayingCenter.nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        nowPlayingCenter.nowPlayingInfo = info
    }

    private func updateNowPlayingElapsed(force: Bool) {
        guard currentSong != nil else { return }
        var info = nowPlayingCenter.nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        nowPlayingCenter.nowPlayingInfo = info
        if force { lastElapsedUpdate = Date().timeIntervalSince1970 }
    }

    private func updateNowPlayingElapsedIfNeeded(currentTime: Double, duration: Double) {
        guard currentSong != nil else { return }
        let now = Date().timeIntervalSince1970
        // Update about once per second while playing; iOS animates between updates.
        if isPlaying, now - lastElapsedUpdate >= 1.0 {
            lastElapsedUpdate = now
            updateNowPlayingElapsed(force: false)
        }
    }

    /// Clears everything except the currently playing song.
    func clearUpcomingQueue() {
        guard let current = currentSong else { return }
        queue = [current]
        let urls = [URL(string: current.streamURL)].compactMap { $0 }
        let ids = [current.id]
        Task {
            await audioService.replaceQueue(with: urls, startIndex: 0, songIDs: ids)
            await MainActor.run {
                currentSong = current
            }
        }
    }

    /// Reorders the queue (used by queue bottom sheet). Keeps the same current song active.
    func moveQueue(from source: IndexSet, to destination: Int) {
        guard let current = currentSong else { return }
        var src = source
        if let currentIdx = queue.firstIndex(where: { $0.id == current.id }) {
            src.remove(currentIdx) // don't allow moving current track
        }
        guard !src.isEmpty else { return }
        var newQueue = queue
        newQueue.move(fromOffsets: src, toOffset: destination)
        guard let newCurrentIndex = newQueue.firstIndex(where: { $0.id == current.id }) else { return }
        queue = newQueue
        let urls = newQueue.compactMap { URL(string: $0.streamURL) }
        let ids = newQueue.map(\.id)
        Task {
            await audioService.replaceQueue(with: urls, startIndex: newCurrentIndex, songIDs: ids)
            await MainActor.run {
                currentSong = newQueue[newCurrentIndex]
            }
        }
    }
}
