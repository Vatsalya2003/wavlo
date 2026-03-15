import Foundation
import SwiftData

@Model
final class Playlist {

    @Attribute(.unique) var id: String
    var name: String
    var songs: [Song]
    var createdAt: Date
    var isAIGenerated: Bool
    var coverImageURL: String?

    init(
        id: String,
        name: String,
        songs: [Song] = [],
        createdAt: Date = Date(),
        isAIGenerated: Bool = false,
        coverImageURL: String? = nil
    ) {
        self.id = id
        self.name = name
        self.songs = songs
        self.createdAt = createdAt
        self.isAIGenerated = isAIGenerated
        self.coverImageURL = coverImageURL
    }
}
