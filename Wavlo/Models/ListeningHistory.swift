import Foundation
import SwiftData

@Model
final class ListeningHistory {

    var songID: String
    var playedAt: Date
    var completionRatio: Double
    var wasSkipped: Bool
    /// Source of playback: "search" | "recommendation" | "playlist" | "dj" | "mood"
    var source: String?
    /// Optional: for scoring without joining Song (genre of the track when played).
    var genre: String?
    /// Optional: for scoring without joining Song (artist when played).
    var artistName: String?

    init(songID: String, playedAt: Date = Date(), completionRatio: Double, wasSkipped: Bool = false, source: String? = nil, genre: String? = nil, artistName: String? = nil) {
        self.songID = songID
        self.playedAt = playedAt
        self.completionRatio = completionRatio
        self.wasSkipped = wasSkipped
        self.source = source
        self.genre = genre
        self.artistName = artistName
    }
}
