import Foundation

// MARK: - SongMLFeatures

/// ML-friendly representation of a Song with normalized numeric features.
struct SongMLFeatures: Hashable {
    let songID: String
    let title: String
    let artist: String
    let genres: [String]
    let energy: Double           // 0–1
    let valence: Double          // 0–1 (positiveness / happiness)
    let acousticness: Double     // 0–1
    let durationNormalized: Double
    let popularityNormalized: Double

    init(songID: String,
         title: String,
         artist: String,
         genres: [String],
         energy: Double,
         valence: Double,
         acousticness: Double,
         durationNormalized: Double,
         popularityNormalized: Double) {
        self.songID = songID
        self.title = title
        self.artist = artist
        self.genres = genres
        self.energy = SongMLFeatures.clamp(energy)
        self.valence = SongMLFeatures.clamp(valence)
        self.acousticness = SongMLFeatures.clamp(acousticness)
        self.durationNormalized = SongMLFeatures.clamp(durationNormalized)
        self.popularityNormalized = SongMLFeatures.clamp(popularityNormalized)
    }

    static func from(song: Song) -> SongMLFeatures {
        let genres = SongMLFeatures.tokenizeGenres(song.genre)
        let energy = GenreMaps.estimatedEnergy(forGenres: genres)
        let valence = GenreMaps.estimatedValence(forGenres: genres)
        let acousticness = GenreMaps.estimatedAcousticness(forGenres: genres)
        let durationNorm = min(1.0, max(0.0, Double(song.duration) / 600.0))
        // Popularity heuristic: normalize playCount against a soft cap.
        let popularityNorm = min(1.0, Double(song.playCount) / 50.0)
        return SongMLFeatures(
            songID: song.id,
            title: song.title,
            artist: song.artistName,
            genres: genres,
            energy: energy,
            valence: valence,
            acousticness: acousticness,
            durationNormalized: durationNorm,
            popularityNormalized: popularityNorm
        )
    }

    private static func clamp(_ value: Double) -> Double {
        min(1.0, max(0.0, value))
    }

    static func tokenizeGenres(_ raw: String) -> [String] {
        raw
            .lowercased()
            .split(whereSeparator: { $0 == "," || $0 == "/" || $0 == ";" })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

// MARK: - Recommendation Context

/// Snapshot of the current listening context used by the ranking layer.
struct MLRecommendationContext {
    let currentMood: String?
    let hourOfDay: Int
    let dayOfWeek: Int
    let sessionSongCount: Int
    let sessionAvgEnergy: Double
    let recentSkipRate: Double
    let recentGenres: [String]
}

// MARK: - Recommendation Reason

enum RecommendationReason: String, Codable {
    case becauseYouLiked = "Because you liked this"
    case moodMatch = "Matches your mood"
    case discoverNew = "Discover something new"
    case artistDeepDive = "More from this artist"
    case sessionFlow = "Keeps the vibe going"
    case personalMix = "Personal mix for you"
}

// MARK: - MLRecommendation

struct MLRecommendation: Identifiable {
    let id: UUID
    let song: Song
    let score: Double           // 0–1 overall score
    let reason: RecommendationReason
    let skipProbability: Double // 0–1
    let similarityScore: Double // 0–1 content similarity

    init(song: Song,
         score: Double,
         reason: RecommendationReason,
         skipProbability: Double,
         similarityScore: Double) {
        self.id = UUID()
        self.song = song
        self.score = max(0.0, min(1.0, score))
        self.reason = reason
        self.skipProbability = max(0.0, min(1.0, skipProbability))
        self.similarityScore = max(0.0, min(1.0, similarityScore))
    }
}

// MARK: - Genre & Mood Indexes / Heuristics

/// Central place for genre and mood constants used by ranking and feature layers.
enum GenreMaps {
    /// Canonical genre index used for one-hot vectors (23 genres).
    static let genreIndex: [String] = [
        "pop",
        "rock",
        "electronic",
        "dance",
        "hiphop",
        "rnb",
        "soul",
        "jazz",
        "classical",
        "ambient",
        "chillout",
        "lofi",
        "acoustic",
        "indie",
        "folk",
        "blues",
        "metal",
        "punk",
        "funk",
        "latin",
        "instrumental",
        "soundtrack",
        "world"
    ]

    /// Target energy per mood (0–1).
    static let moodEnergyMap: [String: Double] = [
        "chill": 0.3,
        "focused": 0.35,
        "happy": 0.7,
        "energetic": 0.85,
        "sad": 0.25,
        "melancholic": 0.3,
        "angry": 0.9,
        "romantic": 0.5
    ]

    /// Preferred energy per hour of day (0–23).
    static let timeOfDayEnergyMap: [Int: Double] = {
        var map: [Int: Double] = [:]
        for hour in 0..<24 {
            switch hour {
            case 0...5:
                map[hour] = 0.2   // late night, low energy
            case 6...9:
                map[hour] = 0.4   // morning ramp-up
            case 10...16:
                map[hour] = 0.65  // daytime, moderate energy
            case 17...21:
                map[hour] = 0.8   // evening, higher energy
            default:
                map[hour] = 0.5
            }
        }
        return map
    }()

    /// Rough energy estimates per genre (0–1).
    static let genreToEnergyMap: [String: Double] = [
        "pop": 0.7,
        "rock": 0.8,
        "electronic": 0.85,
        "dance": 0.9,
        "hiphop": 0.8,
        "rnb": 0.6,
        "soul": 0.55,
        "jazz": 0.5,
        "classical": 0.3,
        "ambient": 0.2,
        "chillout": 0.25,
        "lofi": 0.3,
        "acoustic": 0.35,
        "indie": 0.55,
        "folk": 0.45,
        "blues": 0.4,
        "metal": 0.95,
        "punk": 0.9,
        "funk": 0.7,
        "latin": 0.8,
        "instrumental": 0.35,
        "soundtrack": 0.4,
        "world": 0.6
    ]

    /// Map genres to closest mood strings.
    static let genreToMoodMap: [String: String] = [
        "pop": "happy",
        "rock": "energetic",
        "electronic": "energetic",
        "dance": "energetic",
        "hiphop": "energetic",
        "rnb": "romantic",
        "soul": "romantic",
        "jazz": "chill",
        "classical": "focused",
        "ambient": "chill",
        "chillout": "chill",
        "lofi": "focused",
        "acoustic": "melancholic",
        "indie": "melancholic",
        "folk": "melancholic",
        "blues": "sad",
        "metal": "angry",
        "punk": "angry",
        "funk": "happy",
        "latin": "happy",
        "instrumental": "focused",
        "soundtrack": "melancholic",
        "world": "happy"
    ]

    // MARK: - Derived estimates

    static func estimatedEnergy(forGenres genres: [String]) -> Double {
        guard !genres.isEmpty else { return 0.5 }
        let values = genres.compactMap { genreToEnergyMap[$0] }
        guard !values.isEmpty else { return 0.5 }
        return values.reduce(0, +) / Double(values.count)
    }

    static func estimatedValence(forGenres genres: [String]) -> Double {
        // Simple heuristic: map mood to typical happiness.
        let moods = genres.compactMap { genreToMoodMap[$0] }
        guard !moods.isEmpty else { return 0.5 }
        let scores = moods.map { mood -> Double in
            switch mood {
            case "happy": return 0.8
            case "energetic": return 0.7
            case "romantic": return 0.65
            case "chill": return 0.6
            case "focused": return 0.55
            case "melancholic": return 0.4
            case "sad": return 0.3
            case "angry": return 0.35
            default: return 0.5
            }
        }
        return scores.reduce(0, +) / Double(scores.count)
    }

    static func estimatedAcousticness(forGenres genres: [String]) -> Double {
        guard !genres.isEmpty else { return 0.5 }
        let scores = genres.map { genre -> Double in
            switch genre {
            case "acoustic", "folk", "indie", "classical":
                return 0.9
            case "jazz", "blues", "world":
                return 0.7
            case "ambient", "chillout", "lofi":
                return 0.6
            case "pop", "rnb", "soul":
                return 0.4
            case "electronic", "dance", "hiphop", "rock", "metal", "punk":
                return 0.2
            default:
                return 0.5
            }
        }
        return scores.reduce(0, +) / Double(scores.count)
    }
}

