//
//  NewChatView.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/7/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct NewChatView: View {
    @Binding var selectedFriend: UserProfile?
    var dismissSheet: () -> Void

    @State private var friends: [UserProfile] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pink.opacity(0.05).ignoresSafeArea()

                if isLoading {
                    ProgressView("Loading friends...")
                } else if friends.isEmpty {
                    Text("You have no friends to message.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(friends) { friend in
                                Button {
                                    selectedFriend = friend
                                    dismissSheet()
                                } label: {
                                    HStack(spacing: 16) {
                                        AsyncImage(url: friend.profilePictureURL) { phase in
                                            if let image = phase.image {
                                                image.resizable().scaledToFill()
                                            } else {
                                                Image(systemName: "person.circle.fill")
                                                    .resizable()
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.pink, lineWidth: 2))

                                        Text(friend.username)
                                            .font(.headline)
                                            .foregroundColor(.pink)

                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top)
                    }
                }
            }
            .navigationTitle("New Chat")
            .onAppear {
                loadFriends()
            }
        }
    }

    func loadFriends() {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("users").document(currentUID).getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  let friendUIDs = data["friends"] as? [String] else {
                isLoading = false
                return
            }

            var loadedFriends: [UserProfile] = []
            let group = DispatchGroup()

            for uid in friendUIDs where !uid.trimmingCharacters(in: .whitespaces).isEmpty {
                group.enter()
                db.collection("users").document(uid).getDocument { friendSnap, _ in
                    if let userData = friendSnap?.data() {
                        let friend = UserProfile(
                            uid: uid,
                            username: userData["username"] as? String ?? "",
                            profilePictureURL: URL(string: userData["photoURL"] as? String ?? ""),
                            hasBeenRequested: false
                        )
                        loadedFriends.append(friend)
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                self.friends = loadedFriends.sorted { $0.username.lowercased() < $1.username.lowercased() }
                self.isLoading = false
            }
        }
    }
}
