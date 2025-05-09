//
//  SessionViewModel.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/8/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class SessionViewModel: ObservableObject {
    @Published var sessions: [StudySession] = []
    private let db = Firestore.firestore()

    func fetchSessions() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        db.collection("sessions")
            .whereField("memberIDs", arrayContains: userID)
            .addSnapshotListener { snapshot, error in
                if let docs = snapshot?.documents {
                    self.sessions = docs.compactMap {
                        try? $0.data(as: StudySession.self)
                    }
                }
            }
    }

    func createSession(name: String, selectedSetIDs: [String: String], completion: @escaping (StudySession?) -> Void) {
        guard let user = Auth.auth().currentUser else { return }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)

        userRef.getDocument { userSnapshot, error in
            guard let userData = userSnapshot?.data(), error == nil else {
                print("Failed to fetch user info: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }

            let preferredName = userData["preferredName"] as? String
            let firstName = userData["firstName"] as? String ?? ""
            let lastName = userData["lastName"] as? String ?? ""
            let displayName = userData["username"] as? String ?? "Unknown"

            let code = String((0..<6).map { _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()! })
            let timestamp = Timestamp(date: Date())
            let newDocRef = db.collection("sessions").document()
            let sessionID = newDocRef.documentID

            let sessionData: [String: Any] = [
                "name": name,
                "creatorID": user.uid,
                "creatorUsername": displayName,
                "setIDs": selectedSetIDs,
                "memberIDs": [user.uid],
                "sessionCode": code,
                "timestamp": timestamp
            ]

            newDocRef.setData(sessionData, merge: true) { error in
                if let error = error {
                    print("Failed to create session: \(error)")
                    completion(nil)
                } else {
                    let session = StudySession(
                        name: name,
                        creatorID: user.uid,
                        creatorUsername: displayName,
                        setIDs: selectedSetIDs,
                        memberIDs: [user.uid],
                        sessionCode: code,
                        timestamp: timestamp
                    )

                    DispatchQueue.main.async {
                        self.sessions.insert(session, at: 0)
                    }

                    completion(session)
                }
            }
        }
    }

    func joinSession(code: String, completion: @escaping (Bool) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        db.collection("sessions")
            .whereField("sessionCode", isEqualTo: code)
            .getDocuments { snapshot, error in
                guard let doc = snapshot?.documents.first else {
                    completion(false)
                    return
                }

                doc.reference.updateData([
                    "memberIDs": FieldValue.arrayUnion([userID])
                ]) { err in
                    completion(err == nil)
                }
            }
    }
}
