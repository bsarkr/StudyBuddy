//
//  SetViewModel.swift
//  StudyBuddy
//
//  Created by Max Hazelton on 4/24/25.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

class SetViewModel: ObservableObject {
    @Published var sets: [StudySet] = []
    private var db = Firestore.firestore()

    func fetchSets(for userId: String) {
        db.collection("sets")
          .whereField("userId", isEqualTo: userId)
          .order(by: "timestamp", descending: true)
          .addSnapshotListener { snapshot, error in
              guard let documents = snapshot?.documents else { return }
              self.sets = documents.compactMap { try? $0.data(as: StudySet.self) }
          }
    }

    func addSet(_ set: StudySet) {
        do {
            _ = try db.collection("sets").addDocument(from: set)
        } catch {
            print("Error adding set: \(error.localizedDescription)")
        }
    }

    func deleteSet(_ set: StudySet) {
        guard let id = set.id else { return }
        db.collection("sets").document(id).delete()
    }
}
