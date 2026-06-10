import Foundation

enum GroqError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case noData
    case decoding(String)
    case http(Int, String)
    case rateLimit
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:   return "Please set your Groq API key in Settings."
        case .invalidResponse: return "Unexpected response from the AI service."
        case .noData:          return "The AI service returned an empty response."
        case .decoding(let m): return "Couldn't parse the AI response: \(m)"
        case .rateLimit:       return "Rate limit reached. Please wait a moment and try again."
        case .http(let code, let msg): return "AI service error (\(code)): \(msg)"
        case .network(let e):  return "Network error: \(e.localizedDescription)"
        }
    }
}

struct GroqMessage: Codable {
    let role: String
    let content: String
}

struct GroqRequest: Codable {
    let model: String
    let messages: [GroqMessage]
    let temperature: Double
    let maxTokens: Int
    let topP: Double
    let stream: Bool

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature, stream
        case maxTokens = "max_tokens"
        case topP = "top_p"
    }
}

struct GroqResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let role: String
            let content: String
        }
        let index: Int
        let message: Message
        let finishReason: String?

        enum CodingKeys: String, CodingKey {
            case index, message
            case finishReason = "finish_reason"
        }
    }
    let id: String
    let choices: [Choice]
}

final class GroqService {
    static let shared = GroqService()
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)
    }

    private var apiKey: String? {
        KeychainService.shared.loadAPIKey()
    }

    // MARK: - Quiz Generation

    func generateQuiz(forTopic topic: String, model: String? = nil) async throws -> [QuizQuestion] {
        guard let key = apiKey, !key.isEmpty else { throw GroqError.missingAPIKey }

        let systemPrompt = """
        You are an expert competitive programming coach. Generate a quiz for the topic: \(topic).
        Return ONLY a valid JSON array (no markdown, no explanation) with exactly 5 questions.
        Each question object must have exactly these fields:
        {
          "id": 1,
          "question": "Question text here",
          "options": ["A) option1", "B) option2", "C) option3", "D) option4"],
          "correct_answer": "A) option1",
          "explanation": "Brief explanation of why this is correct",
          "difficulty": "easy|medium|hard"
        }
        Make questions progressively harder. Include code snippets in questions where appropriate using plain text.
        """

        let body = GroqRequest(
            model: model ?? Constants.defaultGroqModel,
            messages: [
                GroqMessage(role: "system", content: "You output strictly valid JSON arrays only."),
                GroqMessage(role: "user",   content: systemPrompt)
            ],
            temperature: 0.7,
            maxTokens: 3000,
            topP: 0.95,
            stream: false
        )

        let raw = try await sendRequest(body: body, apiKey: key)
        return try parseQuizJSON(raw)
    }

    // MARK: - Test Connection

    func testConnection(model: String? = nil) async throws -> String {
        guard let key = apiKey, !key.isEmpty else { throw GroqError.missingAPIKey }

        let body = GroqRequest(
            model: model ?? Constants.defaultGroqModel,
            messages: [
                GroqMessage(role: "user", content: "Reply with the single word: PONG")
            ],
            temperature: 0.0,
            maxTokens: 8,
            topP: 1.0,
            stream: false
        )

        return try await sendRequest(body: body, apiKey: key)
    }

    // MARK: - Network

    private func sendRequest(body: GroqRequest, apiKey: String) async throws -> String {
        guard let url = URL(string: Constants.groqBaseURL) else { throw GroqError.invalidResponse }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw GroqError.network(error)
        }

        guard let http = response as? HTTPURLResponse else { throw GroqError.invalidResponse }

        if http.statusCode == 429 { throw GroqError.rateLimit }
        guard (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GroqError.http(http.statusCode, msg)
        }

        do {
            let decoded = try JSONDecoder().decode(GroqResponse.self, from: data)
            guard let content = decoded.choices.first?.message.content else {
                throw GroqError.noData
            }
            return content
        } catch {
            throw GroqError.decoding(error.localizedDescription)
        }
    }

    // MARK: - JSON Parsing

    private func parseQuizJSON(_ raw: String) throws -> [QuizQuestion] {
        let cleaned = extractJSON(from: raw)

        if let data = cleaned.data(using: .utf8) {
            do {
                let arr = try JSONDecoder().decode([QuizQuestion].self, from: data)
                if !arr.isEmpty { return arr }
            } catch {
                // try alternate strategies below
            }
        }

        // Strategy 2: try to extract the first JSON array substring
        if let arrayString = extractFirstJSONArray(from: cleaned) {
            if let data = arrayString.data(using: .utf8),
               let arr = try? JSONDecoder().decode([QuizQuestion].self, from: data),
               !arr.isEmpty {
                return arr
            }
        }

        throw GroqError.decoding("Could not find a JSON array in the response.")
    }

    private func extractJSON(from raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("```json") { s = String(s.dropFirst(7)) }
        if s.hasPrefix("```")     { s = String(s.dropFirst(3)) }
        if s.hasSuffix("```")     { s = String(s.dropLast(3)) }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractFirstJSONArray(from text: String) -> String? {
        guard let start = text.firstIndex(of: "[") else { return nil }
        var depth = 0
        for idx in text.indices[start...] {
            let c = text[idx]
            if c == "[" { depth += 1 }
            else if c == "]" {
                depth -= 1
                if depth == 0 {
                    return String(text[start...idx])
                }
            }
        }
        return nil
    }
}
