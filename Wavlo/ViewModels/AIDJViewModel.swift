import Foundation
import SwiftUI
import SwiftData
import os.log
import Combine

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String
    let text: String
    let timestamp: Date
}

/// Response format from Gemini when user wants music: message + specific search queries + optional playlist query.
struct DJResponse: Codable {
    let message: String
    let searchQueries: [String]
    let playlistSearchQuery: String?
}

@MainActor
final class AIDJViewModel: ObservableObject {

    private let gemini = GeminiService()
    private let jiosaavn = JioSaavnService()
    let voiceService = VoiceInputService()
    private let logger = Logger(subsystem: "com.wavlo", category: "AIDJVM")

    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    var isListening: Bool { voiceService.isListening }
    @Published var isSending = false
    @Published var errorMessage: String?
    @Published var suggestedSongs: [Song] = []

    var geminiAPIKey: String?
    var topGenres: [String] = []
    var recentSongs: [String] = []
    var currentMood: String = "chill"

    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let apiKey = geminiAPIKey ?? Constants.Gemini.defaultAPIKey
        guard !apiKey.isEmpty else {
            errorMessage = "Add your Gemini API key in Settings or set Constants.Gemini.defaultAPIKey in code."
            return
        }
        inputText = ""
        messages.append(ChatMessage(role: "user", text: text, timestamp: Date()))
        isSending = true
        errorMessage = nil
        let systemPrompt = Constants.Gemini.djSystemPrompt(
            topGenres: topGenres,
            recentSongs: recentSongs,
            currentMood: currentMood
        )
        do {
            let response = try await gemini.sendMessage(
                apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines),
                message: text,
                systemPrompt: systemPrompt
            )
            await handleDJResponse(response)
        } catch {
            logger.error("AIDJ send failed: \(String(describing: error))")
            errorMessage = error.localizedDescription
        }
        isSending = false
    }

    func requestAuthorization() async {
        await voiceService.requestAuthorization()
    }

    func startListening() async {
        await voiceService.startListening()
    }

    func stopListening() {
        voiceService.stopListening()
        if !voiceService.transcribedText.isEmpty {
            inputText = voiceService.transcribedText
        }
    }

    func updateInputFromVoice() {
        if !voiceService.transcribedText.isEmpty {
            inputText = voiceService.transcribedText
        }
    }

    /// Parses Gemini response: if JSON with message + searchQueries, show message and fetch songs from JioSaavn; otherwise show as plain chat.
    private func handleDJResponse(_ response: String) async {
        guard let jsonData = extractJSON(from: response),
              let djResponse = try? JSONDecoder().decode(DJResponse.self, from: jsonData) else {
            messages.append(ChatMessage(role: "assistant", text: response, timestamp: Date()))
            return
        }

        messages.append(ChatMessage(role: "assistant", text: djResponse.message, timestamp: Date()))

        var saavnSongs: [SaavnSong] = []

        for query in djResponse.searchQueries {
            do {
                let results = try await jiosaavn.searchSongs(query: query, page: 0, limit: 2)
                saavnSongs.append(contentsOf: results)
            } catch {
                continue
            }
        }

        if let playlistQuery = djResponse.playlistSearchQuery, !playlistQuery.isEmpty {
            do {
                let playlists = try await jiosaavn.searchPlaylists(query: playlistQuery, limit: 1)
                if let first = playlists.first, let id = first.id {
                    let detail = try await jiosaavn.getPlaylistDetails(id: id)
                    let list = detail.songs?.results ?? []
                    saavnSongs.append(contentsOf: list.prefix(5))
                }
            } catch {
                // ignore playlist fallback failure
            }
        }

        var seen = Set<String>()
        let deduped = saavnSongs.filter { song in
            guard let sid = song.id, !seen.contains(sid) else { return false }
            seen.insert(sid)
            return true
        }

        suggestedSongs = deduped.map { $0.toSong() }
    }

    /// Extracts a JSON object from the response (between first { and last }).
    private func extractJSON(from text: String) -> Data? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}"),
              start < end else { return nil }
        let jsonString = String(text[start...end])
        return jsonString.data(using: .utf8)
    }
}
