//
//  AuthViewModel.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 4/12/25.
//

import SwiftUI
import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var hasCompletedSetup = false
    @Published var isEmailVerified = false
    @Published var isCreatingAccount = false 

    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        handle = Auth.auth().addStateDidChangeListener { _, user in
            DispatchQueue.main.async {
                if let user = user {
                    self.isLoggedIn = true
                    self.checkUserProfile(user: user)
                } else {
                    self.isLoggedIn = false
                    self.hasCompletedSetup = false
                    self.isEmailVerified = false
                    self.isCreatingAccount = false
                }
            }
        }
    }

    func checkUserProfile(user: User) {
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).getDocument { snapshot, _ in
            if let data = snapshot?.data() {
                self.hasCompletedSetup = data["setupComplete"] as? Bool ?? false
                self.isEmailVerified = user.isEmailVerified
            } else {
                self.hasCompletedSetup = false
                self.isEmailVerified = user.isEmailVerified
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
            hasCompletedSetup = false
            isEmailVerified = false
            isCreatingAccount = false
        } catch {
            print("Failed to sign out: \(error.localizedDescription)")
        }
    }
}
