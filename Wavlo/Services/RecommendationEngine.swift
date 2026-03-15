import Foundation
import SwiftData

struct RecommendationEngine {

    static func score(
        song: Song,
        history: [ListeningHistory],
        liked: [Song]
    ) -> Double {
        var score = 0.0
        let plays = history.filter { $0.songID == song.id }
        let playCount = plays.count
        let isLiked = liked.contains { $0.id == song.id }
        let avgCompletion = plays.isEmpty ? 0.0 : plays.map(\.completionRatio).reduce(0, +) / Double(plays.count)
        score += Double(playCount) * 2.0
        score += isLiked ? 3.0 : 0.0
        score += avgCompletion * 1.5
        if !plays.filter(\.wasSkipped).isEmpty {
            score -= 1.0
        }
        return score
    }

    static func recommend(
        from candidates: [Song],
        history: [ListeningHistory],
        liked: [Song],
        limit: Int = 20
    ) -> [Song] {
        candidates
            .map { (song: $0, score: score(song: $0, history: history, liked: liked)) }
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map(\.song)
    }

    /// Fetch JioSaavn-based suggestions for a song; merge with local `recommend(from:...)` for hybrid results.
    static func jiosaavnSuggestions(service: JioSaavnService, songId: String, limit: Int = 10) async throws -> [Song] {
        let saavnSongs = try await service.getSongSuggestions(songId: songId, limit: limit)
        return saavnSongs.map { $0.toSong() }
    }
}
