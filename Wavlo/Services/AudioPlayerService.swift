import Foundation
import AVFoundation
import ObjectiveC
import os.log

private enum AVPlayerItemWavloKey {
    static var songID: UInt8 = 0
}

extension AVPlayerItem {
    var wavloSongID: String? {
        get { objc_getAssociatedObject(self, &AVPlayerItemWavloKey.songID) as? String }
        set { objc_setAssociatedObject(self, &AVPlayerItemWavloKey.songID, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

actor AudioPlayerService {

    private let logger = Logger(subsystem: "com.wavlo", category: "AudioPlayer")
    private var queuePlayer: AVQueuePlayer?
    private var timeObserver: Any?
    private var currentItemObserver: NSKeyValueObservation?
    private var statusObserver: NSKeyValueObservation?
    /// Last current item ID so we can detect when a song finishes (transition to next or nil).
    private var lastCurrentItemID: String?
    /// Last item in queue so we can append new items after it.
    private var lastQueuedItem: AVPlayerItem?

    nonisolated(unsafe) var onPlaybackProgress: ((Double, Double) -> Void)?
    /// Called when a track finishes (natural end). Passes the finished song ID.
    nonisolated(unsafe) var onPlaybackFinished: ((String?) -> Void)?
    nonisolated(unsafe) var onCurrentItemChanged: ((String?) -> Void)?
    /// Called when the player play/pause state changes (driven by timeControlStatus).
    nonisolated(unsafe) var onIsPlayingChanged: ((Bool) -> Void)?

    init() {
        setupPlayer()
    }

    private func setupPlayer() {
        queuePlayer = AVQueuePlayer()
        queuePlayer?.actionAtItemEnd = .advance
        addPeriodicTimeObserver()
        observeCurrentItem()
        observeTimeControlStatus()
    }

    private func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = queuePlayer?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak queuePlayer] time in
            guard let player = queuePlayer else { return }
            let current = time.seconds
            guard let item = player.currentItem, item.status == .readyToPlay else { return }
            let duration = item.duration.seconds
            guard duration.isFinite, duration > 0 else { return }
            Task { [current, duration] in
                // Hop to the actor to safely read the callback reference
                let callback = await self.onPlaybackProgress
                await MainActor.run {
                    callback?(current, duration)
                }
            }
        }
    }

    private func observeCurrentItem() {
        currentItemObserver = queuePlayer?.observe(\.currentItem, options: [.new]) { [weak queuePlayer] player, _ in
            let id = (player.currentItem as? AVPlayerItem)?.wavloSongID
            Task { [id] in
                await self.handleCurrentItemChanged(newID: id)
            }
        }
    }

    private func observeTimeControlStatus() {
        statusObserver = queuePlayer?.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            let playing = player.timeControlStatus == .playing
            Task { [playing] in
                let callback = await self?.onIsPlayingChanged
                await MainActor.run {
                    callback?(playing)
                }
            }
        }
    }

    private func handleCurrentItemChanged(newID: String?) {
        if let previousID = lastCurrentItemID, previousID != newID {
            let callback = onPlaybackFinished
            Task { @MainActor in callback?(previousID) }
        }
        lastCurrentItemID = newID
        let callback = onCurrentItemChanged
        Task { @MainActor in callback?(newID) }
    }

    func replaceQueue(with urls: [URL], startIndex: Int = 0, songIDs: [String]) {
        queuePlayer?.removeAllItems()
        lastQueuedItem = nil
        lastCurrentItemID = nil
        guard !urls.isEmpty, startIndex < urls.count else { return }
        let assets = urls.map { AVURLAsset(url: $0) }
        var after: AVPlayerItem? = nil
        for (index, asset) in assets.enumerated() {
            let item = AVPlayerItem(asset: asset)
            item.wavloSongID = index < songIDs.count ? songIDs[index] : ""
            if queuePlayer?.canInsert(item, after: after) == true {
                queuePlayer?.insert(item, after: after)
                after = item
            }
        }
        lastQueuedItem = after
        queuePlayer?.seek(to: .zero)
        if startIndex > 0 {
            for _ in 0..<startIndex {
                queuePlayer?.advanceToNextItem()
            }
        }
        lastCurrentItemID = songIDs[safe: startIndex]
        let startID = songIDs[safe: startIndex]
        Task { @MainActor in onCurrentItemChanged?(startID) }
    }

    /// Appends songs to the end of the queue (for auto-queue recommendations).
    func appendToQueue(urls: [URL], songIDs: [String]) {
        guard !urls.isEmpty, let player = queuePlayer else { return }
        var after = lastQueuedItem
        for (index, url) in urls.enumerated() {
            let item = AVPlayerItem(asset: AVURLAsset(url: url))
            item.wavloSongID = index < songIDs.count ? songIDs[index] : ""
            if player.canInsert(item, after: after) {
                player.insert(item, after: after)
                after = item
            }
        }
        lastQueuedItem = after
    }

    func play() {
        queuePlayer?.play()
    }

    func pause() {
        queuePlayer?.pause()
    }

    func togglePlayPause() {
        if queuePlayer?.rate ?? 0 > 0 {
            queuePlayer?.pause()
        } else {
            queuePlayer?.play()
        }
    }

    func seek(to seconds: Double) {
        queuePlayer?.seek(to: CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
    }

    func skipToNext() {
        queuePlayer?.advanceToNextItem()
    }

    func skipToPrevious() {
        guard let player = queuePlayer else { return }
        let current = player.currentTime().seconds
        if current > 3 {
            player.seek(to: .zero)
        } else {
            player.advanceToNextItem()
            player.seek(to: .zero)
        }
    }

    var isPlaying: Bool {
        (queuePlayer?.rate ?? 0) > 0
    }

    func currentTime() -> Double {
        queuePlayer?.currentTime().seconds ?? 0
    }

    func currentDuration() -> Double {
        queuePlayer?.currentItem?.duration.seconds ?? 0
    }

    deinit {
        if let observer = timeObserver {
            queuePlayer?.removeTimeObserver(observer)
        }
        currentItemObserver?.invalidate()
        statusObserver?.invalidate()
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
