import Foundation
import SwiftData

@Model
final class UserPreferences {

    var preferredGenres: [String]
    var moodHistory: [String]
    var geminiAPIKey: String?

    var displayName: String?
    var playbackCrossfade: Bool
    var playbackGapless: Bool
    var autoPlaySimilar: Bool
    var streamingQuality: String
    var listeningHistoryEnabled: Bool
    var privateSession: Bool
    var preferredMusicLanguage: String?

    init(
        preferredGenres: [String] = [],
        moodHistory: [String] = [],
        geminiAPIKey: String? = nil,
        displayName: String? = nil,
        playbackCrossfade: Bool = false,
        playbackGapless: Bool = true,
        autoPlaySimilar: Bool = true,
        streamingQuality: String = "normal",
        listeningHistoryEnabled: Bool = true,
        privateSession: Bool = false,
        preferredMusicLanguage: String? = nil
    ) {
        self.preferredGenres = preferredGenres
        self.moodHistory = moodHistory
        self.geminiAPIKey = geminiAPIKey
        self.displayName = displayName
        self.playbackCrossfade = playbackCrossfade
        self.playbackGapless = playbackGapless
        self.autoPlaySimilar = autoPlaySimilar
        self.streamingQuality = streamingQuality
        self.listeningHistoryEnabled = listeningHistoryEnabled
        self.privateSession = privateSession
        self.preferredMusicLanguage = preferredMusicLanguage
    }
}
