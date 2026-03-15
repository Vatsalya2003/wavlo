import Foundation
import SwiftUI
import SwiftData
import os.log
import Combine

@MainActor
final class SearchViewModel: ObservableObject {

    private let jiosaavn = JioSaavnService()
    private let logger = Logger(subsystem: "com.wavlo", category: "SearchVM")
    private var searchTask: Task<Void, Never>?
    private let debounceInterval: Duration = .milliseconds(400)

    @Published var searchText = ""
    @Published var searchResults: [Song] = []
    @Published var genreTracks: [String: [Song]] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?

    func searchTextChanged() {
        searchTask?.cancel()
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            searchResults = []
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: debounceInterval)
            guard !Task.isCancelled else { return }
            await performSearch()
        }
    }

    func performSearch() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let saavnSongs = try await jiosaavn.searchSongs(query: query, page: 0, limit: 30)
            searchResults = saavnSongs.map { $0.toSong() }
        } catch {
            logger.error("Search failed: \(String(describing: error))")
            errorMessage = error.localizedDescription
            searchResults = []
        }
        isLoading = false
    }

    func loadGenre(_ genre: String) async {
        do {
            let saavnSongs = try await jiosaavn.searchSongs(query: genre, page: 0, limit: 15)
            genreTracks[genre] = saavnSongs.map { $0.toSong() }
        } catch {
            logger.error("Genre load failed: \(String(describing: error))")
        }
    }
}
