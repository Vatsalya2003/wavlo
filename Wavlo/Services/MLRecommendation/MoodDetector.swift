import Foundation
import NaturalLanguage

struct MoodDetector {

    // MARK: - Public API

    func detectMood(from text: String) -> String {
        let lowered = text.lowercased()

        // 1. Keyword based detection first.
        for (mood, keywords) in keywordMap {
            if keywords.contains(where: { lowered.contains($0) }) {
                return mood
            }
        }

        // 2. Fallback to sentiment.
        let score = sentimentScore(for: text)
        if score >= 0.3 {
            return "happy"
        } else if score >= 0.0 {
            return "chill"
        } else if score >= -0.3 {
            return "melancholic"
        } else {
            return "sad"
        }
    }

    func moodToJamendoTags(mood: String) -> [String] {
        switch mood {
        case "chill":
            return ["chillout", "ambient", "lofi", "relaxing"]
        case "energetic":
            return ["electronic", "upbeat", "dance", "pop"]
        case "focused":
            return ["instrumental", "classical", "ambient", "study"]
        case "sad":
            return ["acoustic", "melancholic", "indie", "blues"]
        case "happy":
            return ["pop", "funk", "upbeat", "feel-good"]
        case "angry":
            return ["rock", "metal", "intense", "punk"]
        case "romantic":
            return ["rnb", "soul", "jazz", "love"]
        case "melancholic":
            return ["indie", "acoustic", "folk", "piano"]
        default:
            return ["pop"]
        }
    }

    // MARK: - Internals

    private let keywordMap: [String: [String]] = [
        "chill": ["chill", "relax", "calm", "wind down", "peaceful", "mellow", "unwind"],
        "energetic": ["energy", "pump", "workout", "hype", "party", "lit", "upbeat", "gym"],
        "happy": ["happy", "joy", "good mood", "cheerful", "bright", "fun", "excited"],
        "sad": ["sad", "down", "depressed", "lonely", "heartbreak", "cry", "missing"],
        "focused": ["focus", "study", "work", "concentrate", "productive", "coding", "reading"],
        "angry": ["angry", "mad", "frustrated", "rage", "intense", "aggressive"],
        "romantic": ["love", "romantic", "date", "crush", "heart", "valentine"],
        "melancholic": ["nostalgic", "bittersweet", "rainy", "reflective", "thoughtful"]
    ]

    private func sentimentScore(for text: String) -> Double {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        let (tag, _) = tagger.tag(at: text.startIndex,
                                  unit: .paragraph,
                                  scheme: .sentimentScore)
        if let value = tag?.rawValue, let score = Double(value) {
            return max(-1.0, min(1.0, score))
        }
        return 0.0
    }
}

