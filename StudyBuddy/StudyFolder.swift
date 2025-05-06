//
//  StudyFolder.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/5/25.
//

import Foundation
import FirebaseFirestore

struct StudyFolder: Identifiable {
    var id: String
    var name: String
    var setIDs: [String]
    var timestamp: Timestamp

    init?(id: String, data: [String: Any]) {
        guard let name = data["name"] as? String,
              let setIDs = data["setIDs"] as? [String],
              let timestamp = data["timestamp"] as? Timestamp else {
            return nil
        }

        self.id = id
        self.name = name
        self.setIDs = setIDs
        self.timestamp = timestamp
    }
}
