//
//  StudySet.swift
//  StudyBuddy
//
//  Created by Max Hazelton on 4/24/25.
//

import Foundation
import FirebaseFirestore

struct FlashcardTerm: Identifiable, Codable {
    var id = UUID()
    var term: String
    var definition: String
}

struct StudySet: Identifiable {
    var id: String
    var title: String
    var terms: [FlashcardTerm]
    var userId: String
    var timestamp: Timestamp

    init?(id: String, data: [String: Any]) {
        guard let title = data["title"] as? String,
              let termsData = data["terms"] as? [[String: String]],
              let userId = data["userId"] as? String,
              let timestamp = data["timestamp"] as? Timestamp else {
            return nil
        }

        self.id = id
        self.title = title
        self.userId = userId
        self.timestamp = timestamp
        self.terms = termsData.map {
            FlashcardTerm(term: $0["term"] ?? "", definition: $0["definition"] ?? "")
        }
    }
}

