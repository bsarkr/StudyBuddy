//  FriendsTabView.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/6/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

//Notification Extension
extension Notification.Name {
    static let refreshFriendsList = Notification.Name("refreshFriendsList")
    static let refreshRequestBadges = Notification.Name("refreshRequestBadges")
}

struct FriendsTabView: View {
    @State private var searchUsername: String = ""
    @State private var foundUsers: [UserProfile] = []
    @State private var searchStatus: String? = nil
    @State private var friendRequestsSheetPresented = false
    @State private var acceptedRequestsSheetPresented = false
    @State private var friends: [UserProfile] = []
    @State private var hasPendingFriendRequests = false
    @State private var hasAcceptedRequests = false
    @State private var selectedFriend: UserProfile? = nil

    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 24) {
                    // Find a Friend
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Find a Friend")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.pink)

                            Spacer()

                            ZStack(alignment: .topTrailing) {
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
                                .sheet(isPresented: $friendRequestsSheetPresented, onDismiss: {
                                    checkRequestBadges()
                                }) {
                                    FriendRequestsView()
                                        .presentationDetents([.medium])
                                        .presentationDragIndicator(.visible)
                                }

                                if hasPendingFriendRequests {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 10, height: 10)
                                        .offset(x: 8, y: -8)
                                }
                            }
                        }
                        .padding(.horizontal)

                        HStack {
                            TextField("Enter a username", text: $searchUsername)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .onChange(of: searchUsername) { _ in
                                    searchForUsers()
                                }
                        }
                        .padding(.horizontal)

                        VStack {
                            if !searchUsername.isEmpty && !foundUsers.isEmpty {
                                ScrollView(.vertical, showsIndicators: false) {
                                    LazyVStack(spacing: 16) {
                                        ForEach(foundUsers) { user in
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
                                                    toggleFriendRequest(to: user)
                                                }) {
                                                    Text(user.hasBeenRequested ? "Requested" : "Add Friend")
                                                        .foregroundColor(.white)
                                                        .padding(.horizontal)
                                                        .padding(.vertical, 6)
                                                        .background(user.hasBeenRequested ? Color.gray : Color.pink)
                                                        .cornerRadius(10)
                                                }
                                            }
                                            .padding()
                                            .background(Color.white)
                                            .cornerRadius(16)
                                            .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                                            .padding(.horizontal, 20)
                                        }
                                    }
                                }
                            } else if let status = searchStatus, !searchUsername.isEmpty {
                                Text(status)
                                    .foregroundColor(.red)
                                    .padding(.horizontal)
                            }
                        }
                        .frame(height: geometry.size.height * 0.15)
                    }

                    Divider().padding(.horizontal)

                    // Friends List
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Your Friends")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.pink)

                            Spacer()

                            ZStack(alignment: .topTrailing) {
                                Button(action: {
                                    acceptedRequestsSheetPresented = true
                                }) {
                                    Image(systemName: "person.crop.circle.badge.checkmark")
                                        .font(.title2)
                                        .padding(8)
                                        .background(Color.pink)
                                        .foregroundColor(.white)
                                        .clipShape(Circle())
                                }
                                .sheet(isPresented: $acceptedRequestsSheetPresented, onDismiss: {
                                    checkRequestBadges()
                                }) {
                                    AcceptedFriendRequestView()
                                        .presentationDetents([.medium])
                                        .presentationDragIndicator(.visible)
                                }

                                if hasAcceptedRequests {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 10, height: 10)
                                        .offset(x: 8, y: -8)
                                }
                            }
                        }
                        .padding(.horizontal)

                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 16) {
                                ForEach(friends) { friend in
                                    HStack(spacing: 12) {
                                        Button(action: {
                                            selectedFriend = friend
                                        }) {
                                            HStack(spacing: 12) {
                                                AsyncImage(url: friend.profilePictureURL) { phase in
                                                    switch phase {
                                                    case .empty:
                                                        ProgressView().frame(width: 50, height: 50)
                                                    case .success(let image):
                                                        image.resizable().scaledToFill()
                                                    case .failure:
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
                                        }
                                        .buttonStyle(PlainButtonStyle())

                                        HStack(spacing: 16) {
                                            Button(action: {
                                                // future messaging feature
                                            }) {
                                                Image(systemName: "message")
                                                    .font(.title3)
                                                    .foregroundColor(.purple)
                                            }

                                            Button(action: {
                                                removeFriend(friend)
                                            }) {
                                                Image(systemName: "trash")
                                                    .font(.title3)
                                                    .foregroundColor(.red)
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(16)
                                    .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                                    .padding(.horizontal, 20)
                                }
                            }
                            .padding(.top, 4)
                        }
                        .frame(height: geometry.size.height * 0.35)
                    }

                    Spacer(minLength: 10)
                }
                .padding(.top)
            }
        }
        .sheet(item: $selectedFriend) { user in
            UserProfileSheetView(userID: user.uid)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            loadFriends()
            checkRequestBadges()
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshFriendsList)) { _ in
            loadFriends()
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshRequestBadges)) { _ in
            checkRequestBadges()
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    func removeFriend(_ user: UserProfile) {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(currentUID).updateData([
            "friends": FieldValue.arrayRemove([user.uid])
        ]) { _ in
            loadFriends()
        }
    }

    func checkRequestBadges() {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("friendRequests")
            .whereField("to", isEqualTo: currentUID)
            .addSnapshotListener { snapshot, _ in
                hasPendingFriendRequests = !(snapshot?.isEmpty ?? true)
            }

        db.collection("acceptedFriendRequests")
            .whereField("to", isEqualTo: currentUID)
            .addSnapshotListener { snapshot, _ in
                hasAcceptedRequests = !(snapshot?.isEmpty ?? true)
            }
    }

    func loadFriends() {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("users").document(currentUID).getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  let friendUIDs = data["friends"] as? [String] else { return }

            var loadedFriends: [UserProfile] = []
            let group = DispatchGroup()

            for uid in friendUIDs.map({ $0.trimmingCharacters(in: .whitespaces) }) where !uid.isEmpty {
                group.enter()
                db.collection("users").document(uid).getDocument { docSnap, _ in
                    if let userData = docSnap?.data() {
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
                self.friends = loadedFriends
            }
        }
    }

    func searchForUsers() {
        foundUsers = []
        searchStatus = nil

        guard !searchUsername.isEmpty,
              let currentUID = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let friendUIDSet = Set(friends.map { $0.uid })

        db.collection("users")
            .whereField("username", isGreaterThanOrEqualTo: searchUsername.lowercased())
            .whereField("username", isLessThan: searchUsername.lowercased() + "\u{f8ff}")
            .getDocuments { snapshot, error in
                guard let docs = snapshot?.documents, error == nil else {
                    searchStatus = "Something went wrong."
                    return
                }

                if docs.isEmpty {
                    searchStatus = "Username not found"
                    return
                }

                var tempUsers: [UserProfile] = []
                let group = DispatchGroup()

                for doc in docs {
                    let uid = doc.documentID
                    if uid == currentUID || friendUIDSet.contains(uid) { continue }

                    let data = doc.data()
                    group.enter()

                    db.collection("friendRequests")
                        .whereField("from", isEqualTo: currentUID)
                        .whereField("to", isEqualTo: uid)
                        .getDocuments { requestSnapshot, _ in
                            let alreadyRequested = !(requestSnapshot?.isEmpty ?? true)
                            let user = UserProfile(
                                uid: uid,
                                username: data["username"] as? String ?? "",
                                profilePictureURL: URL(string: data["photoURL"] as? String ?? ""),
                                hasBeenRequested: alreadyRequested
                            )
                            tempUsers.append(user)
                            group.leave()
                        }
                }

                group.notify(queue: .main) {
                    self.foundUsers = tempUsers
                }
            }
    }

    func toggleFriendRequest(to user: UserProfile) {
        guard let currentUID = Auth.auth().currentUser?.uid,
              let index = foundUsers.firstIndex(where: { $0.uid == user.uid }) else { return }

        let db = Firestore.firestore()
        let isCurrentlyRequested = foundUsers[index].hasBeenRequested

        if isCurrentlyRequested {
            db.collection("friendRequests")
                .whereField("from", isEqualTo: currentUID)
                .whereField("to", isEqualTo: user.uid)
                .getDocuments { snapshot, _ in
                    snapshot?.documents.forEach { $0.reference.delete() }
                    DispatchQueue.main.async {
                        foundUsers[index].hasBeenRequested = false
                        NotificationCenter.default.post(name: .refreshRequestBadges, object: nil)
                    }
                }
        } else {
            db.collection("friendRequests").addDocument(data: [
                "from": currentUID,
                "to": user.uid,
                "timestamp": Timestamp()
            ]) { error in
                if error == nil {
                    DispatchQueue.main.async {
                        foundUsers[index].hasBeenRequested = true
                        NotificationCenter.default.post(name: .refreshRequestBadges, object: nil)
                    }
                }
            }
        }
    }

    func sendFriendRequest(to user: UserProfile) {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("friendRequests")
            .whereField("from", isEqualTo: currentUID)
            .whereField("to", isEqualTo: user.uid)
            .getDocuments { snapshot, _ in
                if !(snapshot?.isEmpty ?? true) { return }

                db.collection("friendRequests").addDocument(data: [
                    "from": currentUID,
                    "to": user.uid,
                    "timestamp": Timestamp()
                ]) { error in
                    if error == nil,
                       let index = foundUsers.firstIndex(where: { $0.uid == user.uid }) {
                        foundUsers[index].hasBeenRequested = true
                        NotificationCenter.default.post(name: .refreshRequestBadges, object: nil)
                    }
                }
            }
    }
}

struct FriendsTabView_Previews: PreviewProvider {
    static var previews: some View {
        FriendsTabView().environmentObject(AuthViewModel())
    }
}
