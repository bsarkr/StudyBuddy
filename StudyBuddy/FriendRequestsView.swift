//
//  FriendRequestsView.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/6/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FriendRequestsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var requests: [UserProfile] = []
    @State private var loading = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pink.opacity(0.1).ignoresSafeArea()

                VStack {
                    if loading {
                        ProgressView("Loading requests...")
                            .padding()
                    } else if requests.isEmpty {
                        Text("No friend requests.")
                            .foregroundColor(.gray)
                            .padding(.top)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(requests) { user in
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
                                            acceptRequest(from: user)
                                        }) {
                                            Text("Accept")
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.green)
                                                .foregroundColor(.white)
                                                .cornerRadius(10)
                                        }

                                        Button(action: {
                                            declineRequest(from: user)
                                        }) {
                                            Text("Decline")
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.red)
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
                .navigationTitle("Friend Requests")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    loadRequests()
                }
            }
        }
    }

    //Load Requests
    func loadRequests() {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("friendRequests")
            .whereField("to", isEqualTo: currentUID)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching requests:", error.localizedDescription)
                    loading = false
                    return
                }

                guard let docs = snapshot?.documents else {
                    loading = false
                    return
                }

                let senders = docs.map { $0["from"] as? String ?? "" }.filter { !$0.isEmpty }
                fetchUsers(for: senders)
            }
    }

    func fetchUsers(for uids: [String]) {
        let db = Firestore.firestore()
        var fetchedUsers: [UserProfile] = []
        let group = DispatchGroup()

        for rawUID in uids {
            let uid = rawUID.trimmingCharacters(in: .whitespacesAndNewlines)
            if uid.isEmpty {
                print("Skipping empty UID from friendRequests")
                continue
            }

            group.enter()
            db.collection("users").document(uid).getDocument { snapshot, _ in
                if let snapshot = snapshot, snapshot.exists, let data = snapshot.data() {
                    let user = UserProfile(
                        uid: uid,
                        username: data["username"] as? String ?? "",
                        profilePictureURL: URL(string: data["profileImageURL"] as? String ?? ""),
                        hasBeenRequested: false
                    )
                    fetchedUsers.append(user)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.requests = fetchedUsers
            self.loading = false
        }
    }

    //Accept / Decline Logic
    func acceptRequest(from user: UserProfile) {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(currentUID)
        let friendRef = db.collection("users").document(user.uid)

        userRef.setData(["friends": FieldValue.arrayUnion([user.uid])], merge: true) { error1 in
            if let error1 = error1 {
                print("Error updating current user:", error1.localizedDescription)
                return
            }

            friendRef.setData(["friends": FieldValue.arrayUnion([currentUID])], merge: true) { error2 in
                if let error2 = error2 {
                    print("Error updating friend user:", error2.localizedDescription)
                    return
                }

                db.collection("friendRequests")
                    .whereField("from", isEqualTo: user.uid)
                    .whereField("to", isEqualTo: currentUID)
                    .getDocuments { snapshot, error in
                        guard let docs = snapshot?.documents else {
                            print("No request to delete.")
                            return
                        }

                        for doc in docs {
                            doc.reference.delete()
                        }

                        DispatchQueue.main.async {
                            requests.removeAll { $0.uid == user.uid }
                        }
                    }
            }
        }
    }

    func declineRequest(from user: UserProfile) {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("friendRequests")
            .whereField("from", isEqualTo: user.uid)
            .whereField("to", isEqualTo: currentUID)
            .getDocuments { snapshot, error in
                if let docs = snapshot?.documents {
                    for doc in docs {
                        doc.reference.delete()
                    }
                }

                requests.removeAll { $0.uid == user.uid }
            }
    }
}
