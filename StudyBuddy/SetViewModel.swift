//
//  SetViewModel.swift
//  StudyBuddy
//
//  Created by Max Hazelton on 4/24/25.
//

import Foundation
import Firebase
import FirebaseFirestore

class SetViewModel: ObservableObject {
    @Published var sets: [StudySet] = []
    private var db = Firestore.firestore()

    // Save set to: /users/{userId}/sets/{setId}
    func saveSet(title: String, terms: [String: String], userId: String, completion: @escaping (Error?) -> Void) {
        let setId = UUID().uuidString
        let termsArray = terms.map { ["term": $0.key, "definition": $0.value] }

        let data: [String: Any] = [
            "id": setId,
            "title": title,
            "terms": termsArray,
            "userId": userId,
            "timestamp": Timestamp(date: Date())
        ]

        db.collection("users")
            .document(userId)
            .collection("sets")
            .document(setId)
            .setData(data) { error in
                completion(error)
            }
    }

    //Fetch sets from: /users/{userId}/sets
    func fetchSets(for userId: String) {
        db.collection("users")
            .document(userId)
            .collection("sets")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }

                self.sets = documents.compactMap { doc in
                    let data = doc.data()
                    guard let title = data["title"] as? String,
                          let userId = data["userId"] as? String,
                          let termsArray = data["terms"] as? [[String: String]] else {
                        return nil
                    }

                    let terms = termsArray.compactMap { dict in
                        if let term = dict["term"], let definition = dict["definition"] {
                            return FlashcardTerm(term: term, definition: definition)
                        } else {
                            return nil
                        }
                    }

                    return StudySet(id: doc.documentID, title: title, terms: terms, userId: userId)
                }
            }
    }

    //delete a set
    func deleteSet(_ set: StudySet) {
        guard let id = set.id else { return }

        db.collection("users")
            .document(set.userId)
            .collection("sets")
            .document(id)
            .delete()
    }
}


