import Foundation
import os.log

/// Manages auto-queue: triggers recommendation refill when queue is low and appends results to playback.
final class AutoQueueManager {

    private let logger = Logger(subsystem: "com.wavlo", category: "AutoQueueManager")
    private let engine = RecommendationEngine()

    /// Refill threshold: when queue has fewer than this many songs, fetch recommendations.
    static let refillThreshold = 5

    /// If queue has fewer than refillThreshold songs, fetches recommendations and calls onAppend on main actor.
    /// - Parameters:
    ///   - seedSong: Song to base recommendations on (e.g. current or last played).
    ///   - queueCount: Current number of songs in queue (including current).
    ///   - existingQueue: Current queue contents for de-duplication/diversity.
    ///   - userStats: Precomputed from ListeningHistory for scoring.
    ///   - useGemini: Whether to call Gemini when queue is very low (queueCount < 3).
    ///   - onAppend: Called on main actor with new songs to append to queue and player.
    func refillIfNeeded(
        seedSong: Song,
        queueCount: Int,
        existingQueue: [Song],
        userStats: UserListeningStats,
        useGemini: Bool = true,
        onAppend: @escaping @MainActor ([Song]) -> Void
    ) {
        guard queueCount < Self.refillThreshold else {
            logger.debug("Queue has \(queueCount) songs, no refill")
            return
        }
        Task {
            let songs = await engine.recommend(
                seedSong: seedSong,
                queueCount: queueCount,
                existingQueue: existingQueue,
                userStats: userStats,
                useGemini: useGemini
            )
            guard !songs.isEmpty else {
                logger.debug("No recommendations returned")
                return
            }
            logger.debug("Refill: appending \(songs.count) songs")
            await MainActor.run {
                onAppend(songs)
            }
        }
    }
}
