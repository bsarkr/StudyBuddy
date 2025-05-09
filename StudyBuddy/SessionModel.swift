//
//  SessionModel.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/8/25.
//

import Foundation
import FirebaseFirestore

struct StudySession: Identifiable, Codable, Hashable {
    @DocumentID var id: String? // Firebase auto-ID
    var name: String
    var creatorID: String
    var creatorUsername: String
    var setIDs: [String: String] // [setID: creatorUsername]
    var memberIDs: [String]
    var sessionCode: String // unique 6-char alphanumeric
    var timestamp: Timestamp
}
