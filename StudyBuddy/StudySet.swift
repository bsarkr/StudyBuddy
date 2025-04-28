//
//  StudySet.swift
//  StudyBuddy
//
//  Created by Max Hazelton on 4/24/25.
//

import Foundation

struct FlashcardTerm: Identifiable {
    var id = UUID()
    var term: String
    var definition: String
}

struct StudySet: Identifiable {
    var id: String? = nil
    var title: String
    var terms: [FlashcardTerm]
    var userId: String
}

