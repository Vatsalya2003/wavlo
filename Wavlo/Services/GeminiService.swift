import Foundation
import os.log

struct GeminiRequest: Encodable {
    let systemInstruction: SystemInstruction?
    let contents: [Content]
    let generationConfig: GenerationConfig

    struct SystemInstruction: Encodable {
        let parts: [Part]
        struct Part: Encodable {
            let text: String
        }
    }

    struct Content: Encodable {
        let role: String
        let parts: [Part]
        struct Part: Encodable {
            let text: String
        }
    }

    struct GenerationConfig: Encodable {
        let temperature: Double
        let maxOutputTokens: Int
    }
}

struct GeminiResponse: Decodable {
    let candidates: [Candidate]?
    struct Candidate: Decodable {
        let content: Content?
        struct Content: Decodable {
            let parts: [Part]?
            struct Part: Decodable {
                let text: String?
            }
        }
    }
}

actor GeminiService {

    private let logger = Logger(subsystem: "com.wavlo", category: "Gemini")
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func sendMessage(
        apiKey: String,
        message: String,
        systemPrompt: String
    ) async throws -> String {
        guard let url = Constants.Gemini.generateContentURL(apiKey: apiKey) else {
            throw GeminiError.invalidURL
        }
        let body = GeminiRequest(
            systemInstruction: .init(parts: [.init(text: systemPrompt)]),
            contents: [.init(role: "user", parts: [.init(text: message)])],
            generationConfig: .init(
                temperature: Constants.Gemini.temperature,
                maxOutputTokens: Constants.Gemini.maxOutputTokens
            )
        )
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        if http.statusCode != 200 {
            let message = String(data: data, encoding: .utf8) ?? ""
            logger.error("Gemini API error \(http.statusCode): \(message)")
            throw GeminiError.httpStatus(http.statusCode, message: message)
        }
        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = decoded.candidates?.first?.content?.parts?.first?.text else {
            throw GeminiError.emptyResponse
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum GeminiError: Error {
    case invalidURL
    case invalidResponse
    case httpStatus(Int, message: String)
    case emptyResponse
}
