import Foundation
import SwiftData

@Model
final class Song {

    @Attribute(.unique) var id: String
    var title: String
    var artistName: String
    var albumName: String
    var genre: String
    var streamURL: String
    var artworkURL: String
    var duration: Int
    var playCount: Int
    var isLiked: Bool
    var addedAt: Date
    var tags: [String]
    var language: String
    var hasLyrics: Bool
    var jiosaavnPlayCount: String

    init(
        id: String,
        title: String,
        artistName: String,
        albumName: String,
        genre: String,
        streamURL: String,
        artworkURL: String,
        duration: Int,
        playCount: Int = 0,
        isLiked: Bool = false,
        addedAt: Date = Date(),
        tags: [String] = [],
        language: String = "",
        hasLyrics: Bool = false,
        jiosaavnPlayCount: String = ""
    ) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.albumName = albumName
        self.genre = genre
        self.streamURL = streamURL
        self.artworkURL = artworkURL
        self.duration = duration
        self.playCount = playCount
        self.isLiked = isLiked
        self.addedAt = addedAt
        self.tags = tags
        self.language = language
        self.hasLyrics = hasLyrics
        self.jiosaavnPlayCount = jiosaavnPlayCount
    }
}
