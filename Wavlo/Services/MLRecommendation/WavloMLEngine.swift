import Foundation
import SwiftData
import os.log
import Combine

@MainActor
final class WavloMLEngine: ObservableObject {

    @Published var isTraining: Bool = false
    @Published var lastTrainedAt: Date?
    @Published var modelStatus: String = "Not trained yet"

    private let recommenderLayer = MLRecommenderLayer()
    private let skipPredictor = SkipPredictorLayer()
    private let ranker = ContextualRanker()
    private let logger = Logger(subsystem: "com.wavlo", category: "WavloMLEngine")

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Training

    func trainAllModels(songs: [Song], history: [ListeningHistory], likedSongIDs: Set<String>) async {
        guard !songs.isEmpty else {
            modelStatus = "No songs available for training"
            return
        }
        isTraining = true
        modelStatus = "Training models…"

        let topGenres = computeTopGenres(from: songs, likedIDs: likedSongIDs, history: history)

        do {
            try await recommenderLayer.train(songs: songs, history: history, likedSongIDs: likedSongIDs)
        } catch {
            logger.error("Layer 1 train failed: \(String(describing: error))")
        }

        do {
            try await skipPredictor.train(history: history, songs: songs, userTopGenres: topGenres)
        } catch {
            logger.error("Layer 2 train failed: \(String(describing: error))")
        }

        isTraining = false
        lastTrainedAt = Date()
        modelStatus = "Models trained"
        logger.log("✅ ML engine training completed")
    }

    // MARK: - Recommendation entrypoints

    func becauseYouLiked(song: Song,
                         allSongs: [Song],
                         history: [ListeningHistory],
                         likedSongIDs: Set<String>,
                         limit: Int) async -> [MLRecommendation] {
        let context = buildCurrentContext(history: history)
        let candidates = allSongs.filter { $0.id != song.id }
        let topGenres = computeTopGenres(from: allSongs, likedIDs: likedSongIDs, history: history)
        let topArtists = computeTopArtists(history: history, songs: allSongs)
        return await generateRecommendations(from: candidates,
                                             seedSong: song,
                                             context: context,
                                             reason: .becauseYouLiked,
                                             limit: limit,
                                             likedIDs: likedSongIDs,
                                             userTopGenres: topGenres,
                                             topArtists: topArtists,
                                             history: history)
    }

    func moodPlaylist(mood: String,
                      allSongs: [Song],
                      history: [ListeningHistory],
                      likedSongIDs: Set<String>,
                      limit: Int) async -> [MLRecommendation] {
        var context = buildCurrentContext(history: history)
        context = MLRecommendationContext(currentMood: mood,
                                          hourOfDay: context.hourOfDay,
                                          dayOfWeek: context.dayOfWeek,
                                          sessionSongCount: context.sessionSongCount,
                                          sessionAvgEnergy: context.sessionAvgEnergy,
                                          recentSkipRate: context.recentSkipRate,
                                          recentGenres: context.recentGenres)
        let topGenres = computeTopGenres(from: allSongs, likedIDs: likedSongIDs, history: history)
        let topArtists = computeTopArtists(history: history, songs: allSongs)
        return await generateRecommendations(from: allSongs,
                                             seedSong: nil,
                                             context: context,
                                             reason: .moodMatch,
                                             limit: limit,
                                             likedIDs: likedSongIDs,
                                             userTopGenres: topGenres,
                                             topArtists: topArtists,
                                             history: history)
    }

    func discoverMix(allSongs: [Song],
                     likedSongs: [Song],
                     history: [ListeningHistory],
                     likedSongIDs: Set<String>,
                     limit: Int) async -> [MLRecommendation] {
        let context = buildCurrentContext(history: history)
        let topGenres = computeTopGenres(from: allSongs, likedIDs: likedSongIDs, history: history)
        let topArtists = computeTopArtists(history: history, songs: allSongs)

        // Exploit: songs close to liked songs.
        let likedSet = Set(likedSongs.map { $0.id })
        let exploitCandidates = allSongs.filter { !likedSet.contains($0.id) }
        let exploitRecs = await generateRecommendations(from: exploitCandidates,
                                                        seedSong: likedSongs.first,
                                                        context: context,
                                                        reason: .personalMix,
                                                        limit: limit,
                                                        likedIDs: likedSongIDs,
                                                        userTopGenres: topGenres,
                                                        topArtists: topArtists,
                                                        history: history)

        // Explore: songs from genres not in user's top.
        let exploreCandidates = allSongs.filter { song in
            let genres = Set(SongMLFeatures.tokenizeGenres(song.genre))
            return genres.isDisjoint(with: topGenres)
        }
        let exploreRecs = await generateRecommendations(from: exploreCandidates,
                                                        seedSong: likedSongs.first,
                                                        context: context,
                                                        reason: .discoverNew,
                                                        limit: max(1, limit / 3),
                                                        likedIDs: likedSongIDs,
                                                        userTopGenres: topGenres,
                                                        topArtists: topArtists,
                                                        history: history)

        // Interleave 2 exploit, 1 explore.
        var result: [MLRecommendation] = []
        var eIndex = 0
        var xIndex = 0
        while result.count < limit && (xIndex < exploitRecs.count || eIndex < exploreRecs.count) {
            for _ in 0..<2 where xIndex < exploitRecs.count && result.count < limit {
                result.append(exploitRecs[xIndex])
                xIndex += 1
            }
            if eIndex < exploreRecs.count && result.count < limit {
                result.append(exploreRecs[eIndex])
                eIndex += 1
            }
        }
        return diversify(result, maxPerArtist: 2, limit: limit)
    }

    func suggestNext(currentSong: Song,
                     recentlyPlayed: [Song],
                     allSongs: [Song],
                     history: [ListeningHistory],
                     likedSongIDs: Set<String>) async -> Song? {
        let context = buildCurrentContext(history: history)
        let excludeIDs = Set(recentlyPlayed.map { $0.id } + [currentSong.id])
        let candidates = allSongs.filter { !excludeIDs.contains($0.id) }
        guard !candidates.isEmpty else { return nil }
        let topGenres = computeTopGenres(from: allSongs, likedIDs: likedSongIDs, history: history)
        let topArtists = computeTopArtists(history: history, songs: allSongs)
        let recs = await generateRecommendations(from: candidates,
                                                 seedSong: currentSong,
                                                 context: context,
                                                 reason: .sessionFlow,
                                                 limit: 1,
                                                 likedIDs: likedSongIDs,
                                                 userTopGenres: topGenres,
                                                 topArtists: topArtists,
                                                 history: history)
        return recs.first?.song
    }

    // MARK: - Core pipeline

    private func generateRecommendations(from candidates: [Song],
                                         seedSong: Song?,
                                         context: MLRecommendationContext,
                                         reason: RecommendationReason,
                                         limit: Int,
                                         likedIDs: Set<String>,
                                         userTopGenres: Set<String>,
                                         topArtists: Set<String>,
                                         history: [ListeningHistory]) async -> [MLRecommendation] {
        guard !candidates.isEmpty else { return [] }

        let historyBySong = Dictionary(grouping: history, by: { $0.songID })
        let recent24hIDs = computeRecentSongIDs(history: history, days: 1)

        let seedFeatures: SongMLFeatures? = seedSong.map { SongMLFeatures.from(song: $0) }

        var recs: [MLRecommendation] = []

        for song in candidates {
            let features = SongMLFeatures.from(song: song)

            // Features for skip predictor.
            let songGenres = Set(features.genres)
            let genreOverlap = Double(userTopGenres.intersection(songGenres).count)
            let maxOverlap = max(Double(userTopGenres.count), 1.0)
            let genreMatchScore = genreOverlap / maxOverlap

            let artistPlayCount = historyBySong
                .filter { _, entries in entries.contains(where: { $0.artistName == song.artistName }) }
                .flatMap { $0.value }
                .count
            let artistFamiliarity = artistPlayCount > 0 ? min(1.0, Double(artistPlayCount) / 20.0) : 0.0

            let durationNorm = min(1.0, Double(song.duration) / 600.0)
            let completionAvg = historyBySong[song.id].map { entries in
                let ratios = entries.map { max(0.0, min(1.0, $0.completionRatio)) }
                return ratios.reduce(0, +) / Double(max(ratios.count, 1))
            } ?? 0.0

            let skipProb = await skipPredictor.predictSkipProbability(
                genreMatchScore: genreMatchScore,
                artistFamiliarity: artistFamiliarity,
                duration: durationNorm,
                historicalCompletion: completionAvg
            )

            if skipProb > 0.75 {
                continue
            }

            let (score, similarity) = ranker.score(candidate: features,
                                                   seed: seedFeatures,
                                                   context: context,
                                                   skipProbability: skipProb,
                                                   userTopGenres: userTopGenres,
                                                   topArtists: topArtists,
                                                   recentSongIDs: recent24hIDs,
                                                   likedIDs: likedIDs,
                                                   history: history)

            let rec = MLRecommendation(song: song,
                                       score: score,
                                       reason: reason,
                                       skipProbability: skipProb,
                                       similarityScore: similarity)
            recs.append(rec)
        }

        let sorted = recs.sorted { $0.score > $1.score }
        return diversify(sorted, maxPerArtist: 2, limit: limit)
    }

    // MARK: - Helpers

    private func buildCurrentContext(history: [ListeningHistory]) -> MLRecommendationContext {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now)

        let last50 = Array(history.suffix(50))
        let sessionCount = last50.count
        let skipCount = last50.filter { $0.wasSkipped }.count
        let recentSkipRate = sessionCount > 0 ? Double(skipCount) / Double(sessionCount) : 0.0

        let genres = last50.compactMap { $0.genre }.flatMap { SongMLFeatures.tokenizeGenres($0) }
        let energies = genres.map { GenreMaps.genreToEnergyMap[$0] ?? 0.5 }
        let sessionAvgEnergy = energies.isEmpty ? 0.5 : energies.reduce(0, +) / Double(energies.count)

        return MLRecommendationContext(currentMood: nil,
                                       hourOfDay: hour,
                                       dayOfWeek: weekday,
                                       sessionSongCount: sessionCount,
                                       sessionAvgEnergy: sessionAvgEnergy,
                                       recentSkipRate: recentSkipRate,
                                       recentGenres: genres)
    }

    private func computeTopGenres(from songs: [Song],
                                  likedIDs: Set<String>,
                                  history: [ListeningHistory]) -> Set<String> {
        var counts: [String: Int] = [:]
        let likedSongs = songs.filter { likedIDs.contains($0.id) }
        for song in likedSongs {
            for g in SongMLFeatures.tokenizeGenres(song.genre) {
                counts[g, default: 0] += 3 // liked bias
            }
        }
        for entry in history where !entry.wasSkipped {
            if let genre = entry.genre {
                for g in SongMLFeatures.tokenizeGenres(genre) {
                    counts[g, default: 0] += 1
                }
            }
        }
        let sorted = counts.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
        return Set(sorted)
    }

    private func computeTopArtists(history: [ListeningHistory], songs: [Song]) -> Set<String> {
        let songByID = Dictionary(uniqueKeysWithValues: songs.map { ($0.id, $0) })
        var counts: [String: Int] = [:]
        for entry in history {
            if let song = songByID[entry.songID] {
                counts[song.artistName, default: 0] += 1
            }
        }
        let sorted = counts.sorted { $0.value > $1.value }.prefix(10).map { $0.key }
        return Set(sorted)
    }

    private func computeRecentSongIDs(history: [ListeningHistory], days: Int) -> Set<String> {
        guard days > 0 else { return [] }
        let cutoff = Date().addingTimeInterval(-Double(days) * 24 * 3600)
        let ids = history.filter { $0.playedAt >= cutoff }.map { $0.songID }
        return Set(ids)
    }

    private func diversify(_ recs: [MLRecommendation], maxPerArtist: Int, limit: Int) -> [MLRecommendation] {
        var result: [MLRecommendation] = []
        var artistCounts: [String: Int] = [:]
        for rec in recs {
            let artist = rec.song.artistName
            let count = artistCounts[artist, default: 0]
            if count < maxPerArtist {
                result.append(rec)
                artistCounts[artist] = count + 1
            }
            if result.count >= limit {
                break
            }
        }
        return result
    }
}

