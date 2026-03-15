import Foundation
import os.log

actor LyricsService {

    private let logger = Logger(subsystem: "com.wavlo", category: "Lyrics")
    private let session: URLSession
    private let jiosaavn: JioSaavnService

    init(session: URLSession = .shared, jiosaavn: JioSaavnService = JioSaavnService()) {
        self.session = session
        self.jiosaavn = jiosaavn
    }

    /// Fetch lyrics from JioSaavn by song ID.
    func fetchLyrics(songId: String) async throws -> String? {
        try await jiosaavn.getLyrics(songId: songId)
    }
}
