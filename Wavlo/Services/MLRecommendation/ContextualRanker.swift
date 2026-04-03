import Foundation

struct ContextualRanker {
    public func score(candidate: SongMLFeatures,
                      seed: SongMLFeatures?,
                      context: MLRecommendationContext,
                      skipProbability: Double,
                      userTopGenres: Set<String>,
                      topArtists: Set<String>,
                      recentSongIDs: Set<String>,
                      likedIDs: Set<String>,
                      history: [ListeningHistory]) -> (Double, Double) {
        
        let similarity: Double
        if let seed = seed {
            let energySim = 1.0 - abs(candidate.energy - seed.energy)
            let valenceSim = 1.0 - abs(candidate.valence - seed.valence)
            let acousticSim = 1.0 - abs(candidate.acousticness - seed.acousticness)
            let durationSim = 1.0 - abs(candidate.durationNormalized - seed.durationNormalized)
            let genreSim = jaccardIndex(candidate.genres, seed.genres)
            
            similarity = (energySim + valenceSim + acousticSim + durationSim + genreSim) / 5.0
        } else {
            similarity = 0.5
        }
        
        let candidateGenreSet = Set(candidate.genres.map { $0.lowercased() })
        let genreOverlap = Double(candidateGenreSet.intersection(userTopGenres).count)
        let genreAffinity = genreOverlap / Double(max(userTopGenres.count, 1))
        let artistBoost = topArtists.contains(candidate.artist) ? 0.1 : 0.0
        let recencyPenalty = recentSongIDs.contains(candidate.songID) ? -0.15 : 0.0
        let likedBoost = likedIDs.contains(candidate.songID) ? -0.5 : 0.0
        
        var score = 0.45 * similarity + 0.35 * genreAffinity + artistBoost + recencyPenalty + likedBoost
        
        score *= (1.0 - 0.6 * skipProbability)
        
        score = clamp(score, lower: 0.0, upper: 1.0)
        
        return (score, similarity)
    }
    
    // MARK: - Private helpers
    
    private func clamp(_ value: Double, lower: Double, upper: Double) -> Double {
        return min(max(value, lower), upper)
    }
    
    private func jaccardIndex(_ a: [String], _ b: [String]) -> Double {
        let setA = Set(a.map { $0.lowercased() })
        let setB = Set(b.map { $0.lowercased() })
        let intersectionCount = Double(setA.intersection(setB).count)
        let unionCount = Double(setA.union(setB).count)
        guard unionCount > 0 else { return 0.0 }
        return intersectionCount / unionCount
    }
}
