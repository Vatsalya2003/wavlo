import Foundation
import os.log

actor SkipPredictorLayer {
    private let logger = Logger(subsystem: "com.wavlo", category: "SkipPredictor")
    private var lastTrainedAt: Date?

    public func train(history: [ListeningHistory], songs: [Song], userTopGenres: Set<String>) async throws {
        lastTrainedAt = Date()
        logger.log("Training SkipPredictorLayer with history count: \(history.count), songs count: \(songs.count), userTopGenres count: \(userTopGenres.count)")
    }

    public func predictSkipProbability(genreMatchScore: Double, artistFamiliarity: Double, duration: Double, historicalCompletion: Double) async -> Double {
        var base = 0.6 - 0.3 * genreMatchScore - 0.25 * artistFamiliarity

        if duration > 0.9 {
            base += 0.05
        } else if duration < 0.2 {
            base -= 0.05
        }

        base -= 0.4 * historicalCompletion

        return Self.clamp(base)
    }

    private static func clamp(_ v: Double) -> Double {
        if v < 0 { return 0 }
        if v > 1 { return 1 }
        return v
    }
}
