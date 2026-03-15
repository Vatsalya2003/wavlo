import Foundation
import SwiftData

@Model
final class ListeningHistory {

    var songID: String
    var playedAt: Date
    var completionRatio: Double
    var wasSkipped: Bool

    init(songID: String, playedAt: Date = Date(), completionRatio: Double, wasSkipped: Bool = false) {
        self.songID = songID
        self.playedAt = playedAt
        self.completionRatio = completionRatio
        self.wasSkipped = wasSkipped
    }
}
