//
//  AcceptedFriendRequestView.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/7/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AcceptedFriendRequestView: View {
    @Environment(\.dismiss) var dismiss
    @State private var accepted: [UserProfile] = []
    @State private var loading = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pink.opacity(0.1).ignoresSafeArea()

                VStack {
                    if loading {
                        ProgressView("Loading accepted requests...")
                            .padding()
                    } else if accepted.isEmpty {
                        Text("No accepted requests.")
                            .foregroundColor(.gray)
                            .padding(.top)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(accepted) { user in
                                    HStack {
                                        AsyncImage(url: user.profilePictureURL) { phase in
                                            if let image = phase.image {
                                                image.resizable().scaledToFill()
                                            } else {
                                                Color.gray
                                            }
                                        }
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())

                                        Text(user.username)
                                            .font(.headline)

                                        Spacer()

                                        Button(action: {
                                            acknowledge(user)
                                        }) {
                                            Text("OK")
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.purple)
                                                .foregroundColor(.white)
                                                .cornerRadius(10)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.top)
                        }
                    }

                    Spacer()
                }
                .navigationTitle("Accepted Requests")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear(perform: loadAccepted)
            }
        }
    }

    func loadAccepted() {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("acceptedFriendRequests")
            .whereField("to", isEqualTo: currentUID)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching accepted:", error.localizedDescription)
                    loading = false
                    return
                }

                guard let docs = snapshot?.documents else {
                    loading = false
                    return
                }

                let uids = docs.map { $0["from"] as? String ?? "" }.filter { !$0.isEmpty }
                fetchUserProfiles(for: uids)
            }
    }

    func fetchUserProfiles(for uids: [String]) {
        let db = Firestore.firestore()
        var profiles: [UserProfile] = []
        let group = DispatchGroup()

        for uid in uids {
            group.enter()
            db.collection("users").document(uid).getDocument { snapshot, _ in
                if let snapshot = snapshot, snapshot.exists, let data = snapshot.data() {
                    profiles.append(UserProfile(
                        uid: uid,
                        username: data["username"] as? String ?? "",
                        profilePictureURL: URL(string: data["photoURL"] as? String ?? ""),
                        hasBeenRequested: false
                    ))
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.accepted = profiles
            self.loading = false
        }
    }

    func acknowledge(_ user: UserProfile) {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(currentUID).setData([
            "friends": FieldValue.arrayUnion([user.uid])
        ], merge: true)

        db.collection("acceptedFriendRequests")
            .whereField("to", isEqualTo: currentUID)
            .whereField("from", isEqualTo: user.uid)
            .getDocuments { snapshot, _ in
                snapshot?.documents.forEach { $0.reference.delete() }
                accepted.removeAll { $0.uid == user.uid }

                //Notify FriendsTabView to reload friends
                NotificationCenter.default.post(name: .refreshFriendsList, object: nil)
            }
    }
}
