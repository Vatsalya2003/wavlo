import Foundation
import SwiftUI
import SwiftData
import os.log
import Combine

@MainActor
final class LibraryViewModel: ObservableObject {

    private let logger = Logger(subsystem: "com.wavlo", category: "LibraryVM")

    func addToPlaylist(song: Song, playlist: Playlist, context: ModelContext) {
        if !playlist.songs.contains(where: { $0.id == song.id }) {
            playlist.songs.append(song)
            try? context.save()
        }
    }

    func removeFromPlaylist(song: Song, playlist: Playlist, context: ModelContext) {
        playlist.songs.removeAll { $0.id == song.id }
        try? context.save()
    }

    func createPlaylist(name: String, context: ModelContext) -> Playlist {
        let id = UUID().uuidString
        let playlist = Playlist(id: id, name: name, songs: [], createdAt: Date(), isAIGenerated: false)
        context.insert(playlist)
        try? context.save()
        return playlist
    }

    func deletePlaylist(_ playlist: Playlist, context: ModelContext) {
        context.delete(playlist)
        try? context.save()
    }
}

