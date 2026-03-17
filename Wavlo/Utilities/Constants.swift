import Foundation
import SwiftUI

enum Constants {

    // MARK: - JioSaavn API (saavn.dev — deploy from https://github.com/sumitkolhe/jiosaavn-api)

    enum JioSaavn {
        /// Replace with your Vercel deployment URL (e.g. https://your-jiosaavn-api.vercel.app/api).
        static let baseURL = "https://walvo.vercel.app/api"
    }

    // MARK: - Gemini API

    enum Gemini {
        static let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
        static let model = "gemini-flash-latest"
        static let temperature: Double = 0.9
        static let maxOutputTokens = 1024
        /// Default Gemini API key.
        /// - First tries the process environment variable `GEMINI_API_KEY`
        ///   (set in the Xcode scheme or on the device).
        /// - Otherwise falls back to empty string; in that case the app
        ///   should use the user's key from Settings.
        static let defaultAPIKey: String = {
            if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"],
               !envKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return envKey.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return ""
        }()

        static func generateContentURL(apiKey: String) -> URL? {
            URL(string: "\(baseURL)/\(model):generateContent?key=\(apiKey)")
        }

        static func streamContentURL(apiKey: String) -> URL? {
            URL(string: "\(baseURL)/\(model):streamGenerateContent?key=\(apiKey)")
        }

        static func systemPrompt(topGenres: [String], recentSongs: [String], mood: String) -> String {
            """
            You are Wavlo DJ — a cool, laid-back AI music companion inside the Wavlo app. \
            Keep responses conversational, short (2–3 sentences max), and always suggest \
            specific real artist/song names when recommending music.
            User's top genres: \(topGenres.joined(separator: ", "))
            User's recently played: \(recentSongs.joined(separator: ", "))
            Current mood: \(mood)
            Never mention that you are Gemini or made by Google.
            """
        }

        /// Full DJ system prompt for contextual song suggestions. When user wants music, respond with JSON: message, searchQueries, playlistSearchQuery.
        static func djSystemPrompt(topGenres: [String], recentSongs: [String], currentMood: String) -> String {
            let topGenresStr = topGenres.isEmpty ? "none" : topGenres.joined(separator: ", ")
            let recentStr = recentSongs.isEmpty ? "none" : recentSongs.prefix(5).joined(separator: "; ")
            return """
You are Wavlo DJ — the smartest, most emotionally intelligent music companion ever built. You're like a best friend who has listened to every song ever made and always knows the perfect track for any moment.

═══════════════════════════════════════
PERSONALITY & VOICE
═══════════════════════════════════════
- Talk like a cool, music-obsessed friend — not a robot
- Use slang naturally: "bro", "vibe", "hits different", "fire", "slaps"
- Understand Hinglish (Hindi + English mix) perfectly
- Keep responses to 1-2 sentences max — punchy, not preachy
- Show genuine empathy for emotional situations
- Never lecture, never be cringe, never be generic
- Never mention you are Gemini, Google, AI, or a language model
- You ARE the DJ — own it with confidence

═══════════════════════════════════════
CORE ABILITY: UNDERSTAND ANY SITUATION
═══════════════════════════════════════
You must deeply understand the EMOTION, CONTEXT, SITUATION, and VIBE behind what someone says — even if they don't explicitly ask for music. Read between the lines.

EMOTIONAL MAPPING (what they say → what they actually need):
- "I miss my gf/bf" → romantic, longing, emotional ballads (Tum Hi Ho, Someone You Loved)
- "breakup hogaya" / "she left me" → heartbreak anthems, angry-sad, moving-on songs
- "feeling lonely at night" → melancholic, soulful, late-night emotional tracks
- "I got the job!" / "passed my exam" → celebration, hype, feel-good bangers
- "going on a long drive" → road trip vibes, windows-down anthems, travel songs
- "can't sleep" → soft acoustic, ambient, sleep-friendly calm music
- "gym ja raha hu" → high BPM, aggressive energy, pump-up tracks
- "date night" → smooth romantic, classy, sensual R&B/bollywood
- "wedding prep" → sangeet hits, wedding bangers, mehendi songs
- "studying/coding" → instrumental, lo-fi beats, ambient focus (NO lyrics)
- "morning walk" → fresh, light, acoustic, feel-good morning vibes
- "rain outside" → monsoon songs, chai-pe-charcha vibes, romantic rain
- "feeling angry" → aggressive rap, rock, intense beats
- "homesick" → nostalgic bollywood, desi classics, childhood songs
- "vibing alone" → indie, chill, introspective singer-songwriter
- "sad but don't want sad songs" → uplifting emotional, bittersweet hopeful

═══════════════════════════════════════
LANGUAGE & GLOBAL INTELLIGENCE
═══════════════════════════════════════
- You are a WORLDWIDE DJ — not a Bollywood-only DJ
- Default mix: 50% International/English + 30% Hindi/Bollywood + 20% other (Punjabi, Latin, K-Pop, etc.)
- If user types in Hindi/Hinglish → 40% International + 40% Hindi + 20% other
- If user types fully in English → 60% International + 25% Hindi + 15% other
- If user says "English only" or "no Hindi" → 100% International
- If user says "Hindi only" → 100% Hindi/Bollywood/Punjabi
- Include songs from EVERY era and region: American pop, British rock, Latin reggaeton, K-Pop, Afrobeats, Punjabi, Tamil, etc.
- Think GLOBAL Billboard + Spotify Top 50 level hits

═══════════════════════════════════════
RESPONSE FORMAT
═══════════════════════════════════════

WHEN USER WANTS MUSIC (mood, feeling, situation, or explicit request):
Always respond with this EXACT JSON format and nothing else:

{
  "message": "Your short 1-2 sentence response here",
  "searchQueries": [
    "Exact Song Name Artist Name",
    "Exact Song Name Artist Name",
    "Exact Song Name Artist Name",
    "Exact Song Name Artist Name",
    "Exact Song Name Artist Name",
    "Exact Song Name Artist Name"
  ],
  "playlistSearchQuery": "relevant JioSaavn playlist search terms"
}

Rules: Suggest 6-8 REAL songs by REAL artists. Include ARTIST NAME with every song for accurate search. Never make up song names. Prioritize popular, well-known tracks. Every song MUST match the emotional context.

WHEN JUST CHATTING (greeting, question about you, random talk):
Just reply normally with text, no JSON.

═══════════════════════════════════════
CONTEXT FROM USER
═══════════════════════════════════════
User's top genres: \(topGenresStr)
User's recently played: \(recentStr)
Current mood: \(currentMood)

Use this to personalize. Match their taste while introducing songs they might not know yet.
"""
        }

        /// Prompt for lyrics: raw lyrics only, no title/artist/brackets/commentary.
        static func lyricsPrompt(songName: String, artistName: String) -> String {
            """
            Give me the complete lyrics for the song '\(songName)' by '\(artistName)'. Return ONLY the raw lyrics text. No title, no artist name at the top, no commentary, no explanations, no brackets like [Verse] or [Chorus], no annotations. Just the pure lyrics line by line exactly as they are sung.
            """
        }

        /// Prompt for auto-queue recommendations (Layer 3 — Gemini). Returns JSON array of "Song Name Artist Name".
        static func recommendationPrompt(songName: String, artistName: String) -> String {
            """
            Given the user is listening to "\(songName)" by \(artistName), suggest 10 similar songs that match the same vibe, energy, and mood. Consider:
            - Same genre and sub-genre
            - Similar tempo and energy level
            - Same era (recent hits with recent, classics with classics)
            - Artists that fans of \(artistName) typically also enjoy
            - Mix of popular and slightly lesser-known tracks for discovery

            Return ONLY a JSON array of strings, each string is "Song Name Artist Name". Example: ["Starboy The Weeknd", "Save Your Tears The Weeknd"]
            """
        }
    }

    // MARK: - Mood → Search Query (JioSaavn)

    static let moodToQuery: [String: String] = [
        "chill":      "lofi chill relax",
        "energetic":  "party dance upbeat",
        "focused":    "instrumental study ambient",
        "sad":        "sad emotional heartbreak",
        "happy":      "happy feel good",
        "angry":      "intense rock metal",
        "romantic":   "romantic love songs"
    ]

    // MARK: - Available Moods

    static let moods: [(name: String, icon: String)] = [
        ("chill",     "moon.stars.fill"),
        ("energetic", "bolt.fill"),
        ("focused",   "brain.head.profile"),
        ("sad",       "cloud.rain.fill"),
        ("happy",     "sun.max.fill"),
        ("angry",     "flame.fill"),
        ("romantic",  "heart.fill")
    ]

    // MARK: - Genre Catalog

    static let genres: [(name: String, icon: String, color: String)] = [
        ("Pop",         "music.note",          "1DB954"),
        ("Rock",        "guitars.fill",        "E85D75"),
        ("Electronic",  "waveform",            "5DCAA5"),
        ("Hip-Hop",     "headphones",          "F5A623"),
        ("Jazz",        "music.quarternote.3", "D4A5FF"),
        ("Classical",   "pianokeys",           "88C0D0"),
        ("R&B",         "heart.text.square",   "FF6B6B"),
        ("Ambient",     "leaf.fill",           "A3BE8C"),
        ("Indie",       "sparkles",            "EBCB8B"),
        ("Metal",       "bolt.horizontal",     "BF616A"),
        ("Blues",       "drop.fill",           "5E81AC"),
        ("Folk",        "tree.fill",           "D08770")
    ]

    // MARK: - Typography

    enum Typography {
        static let displayLarge = Font.system(size: 34, weight: .black, design: .default)
        static let displayMedium = Font.system(size: 28, weight: .bold, design: .default)
        static let titleLarge = Font.system(size: 22, weight: .bold, design: .default)
        static let titleMedium = Font.system(size: 18, weight: .semibold, design: .default)
        static let bodyLarge = Font.system(size: 16, weight: .medium, design: .default)
        static let bodyRegular = Font.system(size: 15, weight: .regular, design: .default)
        static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .medium, design: .default)
        static let micro = Font.system(size: 10, weight: .semibold, design: .default)
        static let pill = Font.system(size: 14, weight: .semibold, design: .default)
        static let lyricsActive = Font.system(size: 22, weight: .bold, design: .default)
        static let lyricsInactive = Font.system(size: 18, weight: .regular, design: .default)
    }

    // MARK: - Layout

    enum Layout {
        static let screenPadding: CGFloat = 20
        static let cardPadding: CGFloat = 16
        static let baseSpacing: CGFloat = 8
        static let cardCornerRadius: CGFloat = 14
        static let buttonCornerRadius: CGFloat = 28
        static let pillCornerRadius: CGFloat = 20
        static let smallCornerRadius: CGFloat = 8
        static let miniPlayerHeight: CGFloat = 64
        static let miniPlayerArtworkSize: CGFloat = 44
        static let miniPlayerCornerRadius: CGFloat = 12
        static let artworkSizeSmall: CGFloat = 48
        static let artworkSizeMedium: CGFloat = 56
        static let artworkSizeLarge: CGFloat = 280
        static let songRowArtworkSize: CGFloat = 50
        static let songRowCornerRadius: CGFloat = 6
        static let homeCardSize: CGFloat = 160
        static let homeCardCornerRadius: CGFloat = 8
    }

    // MARK: - Animation

    enum Animation {
        static let defaultDuration: Double = 0.3
        static let springResponse: Double = 0.5
        static let springDamping: Double = 0.8
    }

    // MARK: - Tab Items

    enum Tab: String, CaseIterable {
        case home = "Home"
        case search = "Search"
        case library = "Your Library"
        case aidj = "Wavlo DJ"

        var icon: String {
            switch self {
            case .home:    return "house.fill"
            case .search:  return "magnifyingglass"
            case .library: return "books.vertical.fill"
            case .aidj:    return "waveform.circle.fill"
            }
        }
    }
}
