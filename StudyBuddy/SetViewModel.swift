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

    func fetchSets(for userId: String) {
        db.collection("sets")
          .whereField("userId", isEqualTo: userId)
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

    func addSet(_ set: StudySet) {
        let termsData = set.terms.map { ["term": $0.term, "definition": $0.definition] }
        let data: [String: Any] = [
            "title": set.title,
            "terms": termsData,
            "userId": set.userId,
            "timestamp": Timestamp()
        ]

        db.collection("sets").addDocument(data: data) { error in
            if let error = error {
                print("Error adding set: \(error.localizedDescription)")
            }
        }
    }

    func deleteSet(_ set: StudySet) {
        guard let id = set.id else { return }
        db.collection("sets").document(id).delete()
    }
}

