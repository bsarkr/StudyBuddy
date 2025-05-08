//
//  UserProfile.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/8/25.
//

import Foundation

struct UserProfile: Identifiable, Equatable, Codable {
    let id: String
    let uid: String
    let username: String
    let profilePictureURL: URL?
    var hasBeenRequested: Bool

    enum CodingKeys: String, CodingKey {
        case id, uid, username, profilePictureURL, hasBeenRequested
    }

    init(uid: String, username: String, profilePictureURL: URL?, hasBeenRequested: Bool) {
        self.id = uid
        self.uid = uid
        self.username = username
        self.profilePictureURL = profilePictureURL
        self.hasBeenRequested = hasBeenRequested
    }
}
