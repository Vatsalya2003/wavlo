import Foundation
import os.log

/// Layer 1 – collaborative filtering stub suitable for iOS builds without
/// depending on CreateML. It maintains ID maps and timestamps so that
/// higher layers can still reason about retraining cadence.
actor MLRecommenderLayer {

    private let logger = Logger(subsystem: "com.wavlo", category: "MLRecommenderLayer")

    /// Map from Song.id (String) → incremental Int ID (for potential ML usage).
    private(set) var songIDMap: [String: Int] = [:]
    private(set) var reverseSongIDMap: [Int: String] = [:]
    private var lastTrainedAt: Date?

    // MARK: - Public API

    func train(songs: [Song], history: [ListeningHistory], likedSongIDs: Set<String>) async throws {
        guard !songs.isEmpty else {
            logger.log("🧠 Layer 1: no songs available, skipping training")
            return
        }

        var idMap: [String: Int] = [:]
        var reverseMap: [Int: String] = [:]
        for (index, song) in songs.enumerated() {
            let intID = index + 1
            idMap[song.id] = intID
            reverseMap[intID] = song.id
        }
        songIDMap = idMap
        reverseSongIDMap = reverseMap
        lastTrainedAt = Date()

        logger.log("🧠 Layer 1: stub train completed with \(songs.count) songs")
    }

    /// Recommend incremental song IDs. Stub returns empty; contextual ranker +
    /// higher layers handle ordering using content and behavior signals.
    func recommend(count: Int) throws -> [Int] {
        return []
    }

    func needsRetraining() -> Bool {
        guard let last = lastTrainedAt else { return true }
        return Date().timeIntervalSince(last) > 3600
    }
}


