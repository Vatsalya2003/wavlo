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

    nonisolated(unsafe) var onPlaybackProgress: ((Double, Double) -> Void)?
    nonisolated(unsafe) var onPlaybackFinished: (() -> Void)?
    nonisolated(unsafe) var onCurrentItemChanged: ((String?) -> Void)?

    init() {
        setupPlayer()
    }

    private func setupPlayer() {
        queuePlayer = AVQueuePlayer()
        queuePlayer?.actionAtItemEnd = .advance
        addPeriodicTimeObserver()
        observeCurrentItem()
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
                // Hop to the actor to safely read the callback reference
                let callback = await self.onCurrentItemChanged
                await MainActor.run {
                    callback?(id)
                }
            }
        }
    }

    func replaceQueue(with urls: [URL], startIndex: Int = 0, songIDs: [String]) {
        queuePlayer?.removeAllItems()
        guard !urls.isEmpty, startIndex < urls.count else { return }
        let assets = urls.map { AVURLAsset(url: $0) }
        let items = assets.enumerated().map { index, asset -> AVPlayerItem in
            let item = AVPlayerItem(asset: asset)
            item.wavloSongID = index < songIDs.count ? songIDs[index] : ""
            return item
        }
        for item in items {
            if queuePlayer?.canInsert(item, after: nil) == true {
                queuePlayer?.insert(item, after: nil)
            }
        }
        queuePlayer?.seek(to: .zero)
        if startIndex > 0 {
            for _ in 0..<startIndex {
                queuePlayer?.advanceToNextItem()
            }
        }
        onCurrentItemChanged?(songIDs[safe: startIndex])
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
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
