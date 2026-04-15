import Foundation

enum GeminiError: LocalizedError {
    case noAPIKey
    case networkError(Error)
    case invalidResponse
    case parseError

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key set. Open the ClearHead app to add your Gemini API key."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "The server returned an unexpected response."
        case .parseError:
            return "Could not parse the analysis result."
        }
    }
}

final class GeminiService {
    static let shared = GeminiService()
    private init() {}

    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"

    func analyse(text: String) async throws -> FallacyAnalysis {
        guard let apiKey = UserDefaults(suiteName: "group.com.clearhead.shared")?.string(forKey: "apiKey"),
              !apiKey.isEmpty else {
            throw GeminiError.noAPIKey
        }

        let prompt = """
        Analyse the following text for logical fallacies. Return ONLY valid JSON — no markdown, no code fences, no explanation outside the JSON.

        JSON schema:
        {
          "score": <integer 0–100, where 100 = perfectly logical, 0 = deeply flawed>,
          "verdict": "<one sentence summarising the reasoning quality>",
          "fallacies": [
            {
              "name": "<fallacy name>",
              "explanation": "<one sentence in plain English, no jargon>",
              "severity": "<high|medium|low>"
            }
          ]
        }

        If no fallacies are present, return an empty array for "fallacies" and a score of 100.

        Text to analyse:
        \(text)
        """

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [["text": prompt]]
                ]
            ],
            "generationConfig": [
                "temperature": 0.1,
                "responseMimeType": "application/json"
            ]
        ]

        guard let url = URL(string: "\(endpoint)?key=\(apiKey)") else {
            throw GeminiError.invalidResponse
        }

        var request = URLRequest(url: url, timeoutInterval: 10)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, _): (Data, URLResponse)
        do {
            (data, _) = try await URLSession.shared.data(for: request)
        } catch {
            throw GeminiError.networkError(error)
        }

        struct GeminiResponse: Decodable {
            struct Candidate: Decodable {
                struct Content: Decodable {
                    struct Part: Decodable { let text: String }
                    let parts: [Part]
                }
                let content: Content
            }
            let candidates: [Candidate]
        }

        guard let geminiResponse = try? JSONDecoder().decode(GeminiResponse.self, from: data),
              let rawText = geminiResponse.candidates.first?.content.parts.first?.text,
              let jsonData = rawText.data(using: .utf8),
              let analysis = try? JSONDecoder().decode(FallacyAnalysis.self, from: jsonData) else {
            throw GeminiError.parseError
        }

        return analysis
    }
}
