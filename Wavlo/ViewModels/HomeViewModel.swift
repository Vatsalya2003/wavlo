import Foundation
import SwiftUI
import SwiftData
import os.log
import Combine

@MainActor
final class HomeViewModel: ObservableObject {

    private let jiosaavn = JioSaavnService()
    private let logger = Logger(subsystem: "com.wavlo", category: "HomeVM")

    @Published var moodTracks: [Song] = []
    @Published var selectedMood: String = "chill"
    @Published var homeModules: [HomeModule] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadTracksForMood(_ mood: String) async {
        selectedMood = mood
        guard let query = Constants.moodToQuery[mood], !query.isEmpty else {
            moodTracks = []
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let saavnSongs = try await jiosaavn.searchSongs(query: query, page: 0, limit: 25)
            moodTracks = saavnSongs.map { $0.toSong() }
            errorMessage = nil
        } catch {
            logger.error("Home load failed: \(String(describing: error))")
            moodTracks = []
            if let jio = error as? JioSaavnError, case .httpStatus(404) = jio {
                errorMessage = "Search API returned 404. Check Constants.JioSaavn.baseURL (e.g. https://walvo.vercel.app/api) and that your Vercel deployment has the /search/songs route."
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }

    func loadTracksForGenre(_ genre: String) async {
        guard !genre.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        do {
            let saavnSongs = try await jiosaavn.searchSongs(query: genre, page: 0, limit: 25)
            moodTracks = saavnSongs.map { $0.toSong() }
            errorMessage = nil
        } catch {
            logger.error("Home genre load failed: \(String(describing: error))")
            moodTracks = []
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadHomeData() async {
        do {
            let modules = try await jiosaavn.getHomeData(languages: ["hindi", "english"])
            homeModules = modules.filter { mod in
                let items = mod.data ?? []
                return !items.isEmpty
            }
        } catch {
            logger.error("Home modules failed: \(String(describing: error))")
            homeModules = []
            if let jio = error as? JioSaavnError, case .httpStatus(404) = jio {
                // 404 on /modules is OK; mood search will still work
            } else {
                errorMessage = "Home: \(error.localizedDescription)"
            }
        }
    }
}
