import Foundation
import os.log

// MARK: - Data Models

struct SpotifyCSVRow: Sendable {
    let trackName: String
    let artistName: String
}

struct ImportResult {
    let matched: [Song]
    let unmatched: [SpotifyCSVRow]
}

// MARK: - Service

actor SpotifyCSVImportService {

    private let logger = Logger(subsystem: "com.wavlo", category: "SpotifyCSVImport")
    private let saavnService = JioSaavnService()

    // MARK: - Parse

    /// Reads a CSV exported by Exportify and returns rows with trackName + artistName.
    /// Exportify column layout: 0=SpotifyID, 1=Artist Name(s), 2=Track Name, ...
    func parseCSV(url: URL) throws -> [SpotifyCSVRow] {
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)

        var rows: [SpotifyCSVRow] = []

        for line in lines.dropFirst() { // row 0 is the header
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            let fields = parseCSVLine(trimmed)
            guard fields.count >= 3 else { continue }

            let artistName = fields[1].trimmingCharacters(in: .whitespaces)
            let trackName  = fields[2].trimmingCharacters(in: .whitespaces)
            guard !trackName.isEmpty, !artistName.isEmpty else { continue }

            rows.append(SpotifyCSVRow(trackName: trackName, artistName: artistName))
        }

        logger.info("Parsed \(rows.count) rows from CSV")
        return rows
    }

    // MARK: - Match

    /// Searches JioSaavn for every row concurrently in batches of 5.
    /// Calls `onProgress` with the running total of processed songs after each batch.
    func matchSongs(
        rows: [SpotifyCSVRow],
        onProgress: (@Sendable (Int) -> Void)? = nil
    ) async throws -> ImportResult {
        let service = saavnService
        let log     = logger

        var matched:   [Song]           = []
        var unmatched: [SpotifyCSVRow]  = []
        let batchSize = 5
        var processedCount = 0

        let chunks = stride(from: 0, to: rows.count, by: batchSize).map {
            Array(rows[$0 ..< min($0 + batchSize, rows.count)])
        }

        for (chunkIndex, chunk) in chunks.enumerated() {
            var results: [(offset: Int, song: SaavnSong?)] = []

            await withTaskGroup(of: (Int, SaavnSong?).self) { group in
                for (offset, row) in chunk.enumerated() {
                    let query = "\(row.trackName) \(row.artistName)"
                    group.addTask {
                        do {
                            let songs = try await service.searchSongs(query: query, limit: 1)
                            return (offset, songs.first)
                        } catch {
                            log.error("Search failed for '\(query)': \(error.localizedDescription)")
                            return (offset, nil)
                        }
                    }
                }
                for await pair in group {
                    results.append(pair)
                }
            }

            // Maintain original row order within the chunk
            for (offset, saavnSong) in results.sorted(by: { $0.offset < $1.offset }) {
                if let saavnSong {
                    matched.append(saavnSong.toSong())
                } else {
                    unmatched.append(chunk[offset])
                }
            }

            processedCount += chunk.count
            onProgress?(processedCount)

            // 100 ms throttle between batches
            if chunkIndex < chunks.count - 1 {
                try await Task.sleep(nanoseconds: 100_000_000)
            }
        }

        logger.info("Import complete — matched: \(matched.count), unmatched: \(unmatched.count)")
        return ImportResult(matched: matched, unmatched: unmatched)
    }

    // MARK: - Private CSV Parsing

    /// RFC 4180-compliant single-line CSV parser (handles quoted fields with embedded commas
    /// and escaped double-quotes `""`).
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        var i = line.startIndex

        while i < line.endIndex {
            let ch = line[i]
            if ch == "\"" {
                let next = line.index(after: i)
                if inQuotes && next < line.endIndex && line[next] == "\"" {
                    // Escaped quote ""
                    current.append("\"")
                    i = line.index(i, offsetBy: 2)
                    continue
                }
                inQuotes.toggle()
            } else if ch == "," && !inQuotes {
                fields.append(current)
                current = ""
            } else {
                current.append(ch)
            }
            i = line.index(after: i)
        }
        fields.append(current)
        return fields
    }
}
