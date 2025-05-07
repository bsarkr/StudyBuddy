//
//  FriendsTabView.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/6/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FriendsTabView: View {
    @State private var searchUsername: String = ""
    @State private var foundUser: UserProfile? = nil
    @State private var searchStatus: String? = nil
    @State private var friendRequestsSheetPresented = false
    @State private var friends: [UserProfile] = []

    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        ZStack(alignment: .topLeading) {
            

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    //Find a Friend Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Find a Friend")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.pink)

                            Spacer()

                            Button(action: {
                                friendRequestsSheetPresented = true
                            }) {
                                Image(systemName: "person.badge.plus")
                                    .font(.title2)
                                    .padding(10)
                                    .background(Color.pink)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            }
                            .sheet(isPresented: $friendRequestsSheetPresented) {
                                FriendRequestsView()
                            }
                        }
                        .padding(.horizontal)

                        HStack {
                            TextField("Enter a username", text: $searchUsername)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .onSubmit {
                                    searchForUser()
                                }
                        }
                        .padding(.horizontal)

                        if let user = foundUser {
                            HStack(spacing: 12) {
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
                                    sendFriendRequest(to: user)
                                }) {
                                    Text(user.hasBeenRequested ? "Requested" : "Add Friend")
                                        .foregroundColor(.white)
                                        .padding(.horizontal)
                                        .padding(.vertical, 6)
                                        .background(user.hasBeenRequested ? Color.gray : Color.pink)
                                        .cornerRadius(10)
                                }
                                .disabled(user.hasBeenRequested)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(14)
                            .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                            .padding(.horizontal)
                        } else if let status = searchStatus {
                            Text(status)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }
                    }

                    Divider()
                        .padding(.horizontal)

                    //Friends List Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Friends")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.pink)
                            .padding(.horizontal)

                        LazyVStack(spacing: 16) {
                            ForEach(friends) { friend in
                                HStack(spacing: 12) {
                                    AsyncImage(url: friend.profilePictureURL) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(width: 50, height: 50)
                                        case .success(let image):
                                            image.resizable().scaledToFill()
                                        case .failure(_):
                                            Image(systemName: "person.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .foregroundColor(.gray)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())

                                    Text(friend.username)
                                        .font(.headline)

                                    Spacer()
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(14)
                                .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                                .padding(.horizontal)
                            }
                        }
                    }

                    Spacer().frame(height: 40)
                }
                .padding(.top)
            }
        }
        .onAppear {
            loadFriends()
        }
    }

    //Load Friends
    func loadFriends() {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("users").document(currentUID).getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  let friendUIDs = data["friends"] as? [String] else { return }

            var loadedFriends: [UserProfile] = []
            let group = DispatchGroup()

            for rawUID in friendUIDs {
                let uid = rawUID.trimmingCharacters(in: .whitespacesAndNewlines)
                if uid.isEmpty {
                    print("Skipping empty UID in friends array")
                    continue
                }

                group.enter()
                db.collection("users").document(uid).getDocument { docSnap, _ in
                    if let userData = docSnap?.data() {
                        let friend = UserProfile(
                            uid: uid,
                            username: userData["username"] as? String ?? "",
                            profilePictureURL: URL(string: userData["profileImageURL"] as? String ?? ""),
                            hasBeenRequested: false
                        )
                        loadedFriends.append(friend)
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                self.friends = loadedFriends
            }
        }
    }

    //Search Logic
    func searchForUser() {
        let db = Firestore.firestore()
        guard let currentUID = Auth.auth().currentUser?.uid else { return }

        let query = db.collection("users").whereField("username", isEqualTo: searchUsername.lowercased())

        query.getDocuments { snapshot, error in
            if let error = error {
                print("Error searching user:", error.localizedDescription)
                searchStatus = "Something went wrong."
                foundUser = nil
                return
            }

            if let doc = snapshot?.documents.first {
                let data = doc.data()
                let uid = doc.documentID

                // Check if friend request already exists
                db.collection("friendRequests")
                    .whereField("from", isEqualTo: currentUID)
                    .whereField("to", isEqualTo: uid)
                    .getDocuments { requestSnapshot, _ in
                        let alreadyRequested = !(requestSnapshot?.isEmpty ?? true)
                        let user = UserProfile(
                            uid: uid,
                            username: data["username"] as? String ?? "",
                            profilePictureURL: URL(string: data["profileImageURL"] as? String ?? ""),
                            hasBeenRequested: alreadyRequested
                        )
                        foundUser = user
                        searchStatus = nil
                    }

            } else {
                foundUser = nil
                searchStatus = "Username not found"
            }
        }
    }

    //Send Friend Request
    func sendFriendRequest(to user: UserProfile) {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()

        db.collection("friendRequests")
            .whereField("from", isEqualTo: currentUID)
            .whereField("to", isEqualTo: user.uid)
            .getDocuments { snapshot, error in
                if let docs = snapshot?.documents, !docs.isEmpty {
                    print("Request already exists.")
                    foundUser?.hasBeenRequested = true
                    return
                }

                let requestRef = db.collection("friendRequests").document()
                let requestData: [String: Any] = [
                    "from": currentUID,
                    "to": user.uid,
                    "timestamp": Timestamp()
                ]

                requestRef.setData(requestData) { error in
                    if let error = error {
                        print("Error sending request:", error.localizedDescription)
                    } else {
                        print("Friend request sent!")
                        foundUser?.hasBeenRequested = true
                    }
                }
            }
    }
}

struct FriendsTabView_Previews: PreviewProvider {
    static var previews: some View {
        FriendsTabView()
    }
}

struct UserProfile: Identifiable {
    var id: String { uid }
    let uid: String
    let username: String
    let profilePictureURL: URL?
    var hasBeenRequested: Bool
}
