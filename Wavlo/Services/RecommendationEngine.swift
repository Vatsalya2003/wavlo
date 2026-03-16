import Foundation
import os.log

// MARK: - User stats for Layer 4 scoring (computed from SwiftData by caller)

struct UserListeningStats {
    var skippedSongIDs: Set<String> = []
    var topGenreNames: [String] = []
    var topArtistNames: [String] = []
    var recentArtistNames: Set<String> = []
    var playedInSessionIDs: Set<String> = []
    var likedGenreNames: Set<String> = []
}

// MARK: - Scored candidate

private struct ScoredSong {
    let song: Song
    var score: Int
}

// MARK: - Recommendation Engine (4-layer hybrid)

actor RecommendationEngine {

    private let logger = Logger(subsystem: "com.wavlo", category: "RecommendationEngine")
    private let jiosaavn = JioSaavnService()
    private let gemini = GeminiService()

    /// Fetches related songs using Layer 1 (JioSaavn suggestions), Layer 2 (artist expansion), optionally Layer 3 (Gemini), then scores with Layer 4.
    /// - Parameters:
    ///   - seedSong: Current song to base recommendations on.
    ///   - queueCount: Current number of songs in queue (used to decide if we call Gemini).
    ///   - existingQueue: Songs already queued (used for strict de-duplication / diversity).
    ///   - userStats: Precomputed from ListeningHistory for scoring.
    ///   - useGemini: If true and queueCount < 3, will call Gemini for suggestions (uses API quota).
    /// - Returns: Up to 10 songs, deduped and scored; excludes skipped and already-played-in-session.
    func recommend(
        seedSong: Song,
        queueCount: Int,
        existingQueue: [Song],
        userStats: UserListeningStats,
        useGemini: Bool = true
    ) async -> [Song] {
        var candidates: [Song] = []

        // Layer 1: JioSaavn suggestions (primary)
        do {
            let suggested = try await jiosaavn.getSongSuggestions(songId: seedSong.id, limit: 10)
            let songs = suggested.compactMap { saavn -> Song? in
                let s = saavn.toSong()
                return s.streamURL.isEmpty ? nil : s
            }
            candidates.append(contentsOf: songs)
            logger.debug("Layer 1: \(songs.count) suggestions")
        } catch {
            logger.error("Layer 1 failed: \(String(describing: error))")
        }

        // Layer 2: Artist-based expansion (same artist + similar)
        let artistName = seedSong.artistName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !artistName.isEmpty {
            do {
                let artistSongs = try await jiosaavn.searchSongs(query: artistName, page: 0, limit: 10)
                let songs = artistSongs
                    .filter { $0.id != seedSong.id }
                    .compactMap { saavn -> Song? in
                        let s = saavn.toSong()
                        // Filter to keep only songs where primary artist actually matches the seed artist (JioSaavn search is fuzzy).
                        let primary = s.artistName.lowercased()
                        if primary.contains(artistName.lowercased()) && !s.streamURL.isEmpty {
                            return s
                        }
                        return nil
                    }
                candidates.append(contentsOf: songs)
                logger.debug("Layer 2: \(songs.count) artist songs")
            } catch {
                logger.debug("Layer 2 failed: \(String(describing: error))")
            }
        }

        // Layer 3: Gemini (only when queue is low)
        if useGemini, queueCount < 3 {
            do {
                let prompt = Constants.Gemini.recommendationPrompt(songName: seedSong.title, artistName: seedSong.artistName)
                let apiKey = Constants.Gemini.defaultAPIKey
                let text = try await gemini.sendMessage(apiKey: apiKey, message: prompt, systemPrompt: "You are a music recommendation assistant. Reply only with a JSON array of strings.")
                let queries = parseRecommendationJSON(text)
                for query in queries.prefix(8) {
                    guard !query.isEmpty else { continue }
                    if let first = try? await jiosaavn.searchSongs(query: query, page: 0, limit: 1).first {
                        let s = first.toSong()
                        if !s.streamURL.isEmpty, s.id != seedSong.id {
                            candidates.append(s)
                        }
                    }
                }
                logger.debug("Layer 3: added \(min(queries.count, 8)) Gemini suggestions")
            } catch {
                logger.debug("Layer 3 failed: \(String(describing: error))")
            }
        }

        // Strict de-duplication & variant filtering
        var seenIDs = Set(existingQueue.map(\.id))
        var unique: [Song] = []
        for s in candidates {
            guard !seenIDs.contains(s.id),
                  !isDuplicateOrVariant(newSong: s, seedSong: seedSong, existingQueue: existingQueue + unique) else {
                continue
            }
            seenIDs.insert(s.id)
            unique.append(s)
        }

        // Layer 4: Score and rank
        let scored = unique.map { song -> ScoredSong in
            var score = 0
            let genre = song.genre.isEmpty ? (song.language.isEmpty ? "" : song.language) : song.genre
            let artist = song.artistName

            if userStats.skippedSongIDs.contains(song.id) {
                return ScoredSong(song: song, score: -100)
            }
            if userStats.playedInSessionIDs.contains(song.id) {
                return ScoredSong(song: song, score: -100)
            }

            if userStats.topGenreNames.contains(where: { genre.localizedCaseInsensitiveContains($0) }) {
                score += 3
            }
            if userStats.likedGenreNames.contains(where: { genre.localizedCaseInsensitiveContains($0) }) {
                score += 2
            }
            if userStats.topArtistNames.contains(where: { artist.localizedCaseInsensitiveContains($0) }) {
                score += 2
            }
            if userStats.recentArtistNames.contains(where: { artist.localizedCaseInsensitiveContains($0) }) {
                score += 1
            }

            return ScoredSong(song: song, score: score)
        }

        let filtered = scored.filter { $0.score >= 0 }.sorted { $0.score > $1.score }

        // Diversity: max 2 songs per artist in upcoming recommendations,
        // and avoid long runs of the same artist.
        var result: [Song] = []
        var artistCounts: [String: Int] = [:]
        // Seed counts with existing queue so we don't overload an artist overall.
        for song in existingQueue {
            let key = song.artistName.lowercased()
            artistCounts[key, default: 0] += 1
        }

        for scoredSong in filtered {
            guard result.count < 10 else { break }
            let artistKey = scoredSong.song.artistName.lowercased()
            let currentCount = artistCounts[artistKey, default: 0]
            if currentCount >= 2 { continue } // max 2 from same artist in new block

            let lastThree = result.suffix(3).map { $0.artistName.lowercased() }
            if lastThree.count == 3, lastThree.allSatisfy({ $0 == artistKey }) {
                continue
            }

            result.append(scoredSong.song)
            artistCounts[artistKey, default: 0] += 1
        }

        // Light shuffle so sequence isn't too predictable, while keeping first few strong.
        if result.count > 3 {
            let head = Array(result.prefix(3))
            var tail = Array(result.dropFirst(3))
            tail.shuffle()
            return head + tail
        } else {
            return result
        }
    }

    private func parseRecommendationJSON(_ text: String) -> [String] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let start = trimmed.firstIndex(of: "["),
              let end = trimmed.lastIndex(of: "]") else {
            return []
        }
        let json = String(trimmed[start...end])
        guard let data = json.data(using: .utf8),
              let array = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return array
    }

    /// Returns true if the newSong is effectively a duplicate / variant of the seed or something already queued.
    private func isDuplicateOrVariant(newSong: Song, seedSong: Song, existingQueue: [Song]) -> Bool {
        let newTitle = newSong.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let seedTitle = seedSong.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Exact ID match with seed or existing
        if newSong.id == seedSong.id { return true }
        if existingQueue.contains(where: { $0.id == newSong.id }) { return true }

        // Same title as current song (catches remasters, live versions, etc.)
        if newTitle == seedTitle { return true }
        if newTitle.contains(seedTitle) || seedTitle.contains(newTitle) { return true }

        // Same normalized title+artist combo already in queue
        let newKey = "\(newTitle)-\(newSong.artistName.lowercased())"
        if existingQueue.contains(where: {
            "\($0.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))-\($0.artistName.lowercased())" == newKey
        }) {
            return true
        }

        return false
    }
}
