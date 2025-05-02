//
//  ChatGPTService.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/2/25.
//

import Foundation

struct GeneratedFlashcard: Identifiable, Codable {
    var id = UUID()
    let term: String
    let definition: String

    private enum CodingKeys: String, CodingKey {
        case term
        case definition
    }

    init(term: String, definition: String) {
        self.term = term
        self.definition = definition
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        term = try container.decode(String.self, forKey: .term)
        definition = try container.decode(String.self, forKey: .definition)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(term, forKey: .term)
        try container.encode(definition, forKey: .definition)
    }
}

struct FlashcardSetResponse {
    let title: String
    let flashcards: [GeneratedFlashcard]
}

class ChatGPTService {
    static let shared = ChatGPTService()
    
    private let apiKey: String? = Bundle.main.infoDictionary?["OPENAI_API_KEY"] as? String
    private let endpoint = "https://api.openai.com/v1/chat/completions"

    func generateFlashcardSet(from prompt: String, completion: @escaping (Result<FlashcardSetResponse, Error>) -> Void) {
        guard let apiKey = apiKey else {
            completion(.failure(NSError(domain: "Missing API Key", code: 0)))
            return
        }

        let headers = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]

        let systemMessage = """
        You are a flashcard generator. When given a topic, respond ONLY with a raw JSON object like this:

        {
          "title": "Swift Basics",
          "flashcards": [
            { "term": "Variable", "definition": "A named value..." },
            { "term": "Constant", "definition": "A fixed value..." }
          ]
        }

        Do NOT include explanations, markdown, or backticks.
        """

        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": systemMessage],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7
        ]

        guard let url = URL(string: endpoint),
              let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(.failure(NSError(domain: "Invalid request setup", code: 1)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = httpBody

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let data = data {
                print("RAW response:\n" + (String(data: data, encoding: .utf8) ?? "No response string"))
                if let object = try? JSONSerialization.jsonObject(with: data),
                   let prettyData = try? JSONSerialization.data(withJSONObject: object, options: .prettyPrinted),
                   let prettyString = String(data: prettyData, encoding: .utf8) {
                    print("🪄 Pretty JSON:\n\(prettyString)")
                }
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let content = message["content"] as? String
            else {
                completion(.failure(NSError(domain: "Failed to parse response", code: 2)))
                return
            }

            let trimmedContent = content
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            struct RawSetResponse: Decodable {
                let title: String
                let flashcards: [GeneratedFlashcard]
            }

            do {
                let decoded = try JSONDecoder().decode(RawSetResponse.self, from: Data(trimmedContent.utf8))
                completion(.success(FlashcardSetResponse(title: decoded.title, flashcards: decoded.flashcards)))
            } catch {
                print("Decoding failed:", error)
                print("Raw trimmed content:\n\(trimmedContent)")
                completion(.failure(error))
            }
        }.resume()
    }
}
