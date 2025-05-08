//
//  Message.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/7/25.
//

import Foundation
import FirebaseFirestore

struct Message: Identifiable, Codable {
    var id: String
    var senderId: String
    var receiverId: String
    var text: String
    var timestamp: Timestamp

    enum CodingKeys: String, CodingKey {
        case id
        case senderId
        case receiverId
        case text
        case timestamp
    }
}
