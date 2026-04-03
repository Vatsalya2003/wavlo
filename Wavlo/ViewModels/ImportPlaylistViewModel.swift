import Foundation
import Combine
import SwiftData
import os.log

@MainActor
final class ImportPlaylistViewModel: ObservableObject {

    // MARK: - State

    enum ImportState: Equatable {
        case idle
        case parsing
        case matching(current: Int, total: Int)
        case done
        case error
    }

    // MARK: - Published

    @Published var importState: ImportState = .idle
    @Published var matchedSongs:  [Song]           = []
    @Published var unmatchedRows: [SpotifyCSVRow]  = []
    @Published var playlistName:  String           = "My Spotify Playlist"
    @Published var isShowingFilePicker             = false
    @Published var errorMessage:  String?          = nil
    @Published var progress:      Double           = 0.0
    @Published var progressLabel: String           = ""

    // MARK: - Private

    private let service = SpotifyCSVImportService()
    private let logger  = Logger(subsystem: "com.wavlo", category: "ImportPlaylistVM")

    // MARK: - Intent

    func handleFileSelection(url: URL) {
        Task {
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            await performImport(url: url)
        }
    }

    func savePlaylist(context: ModelContext) -> Playlist {
        // For each matched song, reuse the already-persisted object if one exists with
        // the same ID (avoids @Attribute(.unique) conflicts where SwiftData silently drops
        // the insert but the relationship still points to the orphaned in-memory object).
        // Stagger addedAt by 1ms per position on NEW songs so SwiftData's
        // relationship ordering encodes the original CSV sequence.
        // Existing songs keep their real addedAt; we just append them in order.
        let baseDate = Date()
        var resolvedSongs: [Song] = []
        for (index, song) in matchedSongs.enumerated() {
            let songID = song.id
            let descriptor = FetchDescriptor<Song>(predicate: #Predicate { $0.id == songID })
            if let existing = try? context.fetch(descriptor).first {
                resolvedSongs.append(existing)
            } else {
                song.addedAt = baseDate.addingTimeInterval(Double(index) * 0.001)
                context.insert(song)
                resolvedSongs.append(song)
            }
        }

        let playlist = Playlist(
            id:    UUID().uuidString,
            name:  playlistName.isEmpty ? "My Spotify Playlist" : playlistName,
            songs: resolvedSongs
        )
        context.insert(playlist)

        do {
            try context.save()
            logger.info("Saved playlist '\(playlist.name)' with \(playlist.songs.count) songs")
        } catch {
            logger.error("Failed to save playlist: \(error.localizedDescription)")
        }

        return playlist
    }

    func reset() {
        importState  = .idle
        matchedSongs  = []
        unmatchedRows = []
        playlistName  = "My Spotify Playlist"
        errorMessage  = nil
        progress      = 0.0
        progressLabel = ""
    }

    // MARK: - Private

    private func performImport(url: URL) async {
        importState  = .parsing
        progressLabel = "Reading file…"
        progress      = 0.0

        do {
            // 1. Parse CSV
            let rows = try await service.parseCSV(url: url)
            let total = rows.count

            guard total > 0 else {
                errorMessage = "The CSV file appears to be empty or in an unrecognised format."
                importState  = .error
                return
            }

            // 2. Match songs
            importState   = .matching(current: 0, total: total)
            progressLabel = "Searching JioSaavn… 0 of \(total)"

            let result = try await service.matchSongs(rows: rows) { [weak self] matched in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    let pct = Double(matched) / Double(total)
                    self.progress      = pct
                    self.importState   = .matching(current: matched, total: total)
                    self.progressLabel = "Searching JioSaavn… \(matched) of \(total)"
                }
            }

            matchedSongs  = result.matched
            unmatchedRows = result.unmatched
            progress      = 1.0
            progressLabel = ""
            importState   = .done

        } catch {
            logger.error("Import failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            importState  = .error
        }
    }
}

