//
//  StudySet.swift
//  StudyBuddy
//
//  Created by Max Hazelton on 4/24/25.
//

import FirebaseFirestoreSwift

struct FlashcardTerm: Codable, Identifiable {
    @DocumentID var id: String?
    var term: String
    var definition: String
}

struct StudySet: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var terms: [FlashcardTerm]
    var userId: String
    var timestamp: Date = Date()
}
