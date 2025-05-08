//
//  MessagingView.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/7/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MessagingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var searchText = ""
    @State private var showNewChat = false
    @State private var recentChats: [ChatPreview] = []
    @State private var chatListeners: [ListenerRegistration] = []
    
    @State private var selectedFriend: UserProfile? = nil
    @State private var navigateToChat = false

    var currentUID: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    HStack {
                        TextField("Search DMs...", text: $searchText)
                            .padding(10)
                            .background(Color.white)
                            .cornerRadius(10)

                        Button(action: {
                            showNewChat = true
                        }) {
                            Image(systemName: "square.and.pencil")
                                .font(.title2)
                                .padding(10)
                                .background(Color.pink)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                    }
                    .padding()

                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(recentChats.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() })) { chat in
                                NavigationLink(destination: ChatView(otherUser: chat.user)) {
                                    HStack {
                                        AsyncImage(url: chat.user.profilePictureURL) { phase in
                                            if let image = phase.image {
                                                image.resizable().scaledToFill()
                                            } else {
                                                Color.gray
                                            }
                                        }
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())

                                        VStack(alignment: .leading) {
                                            Text(chat.user.username)
                                                .bold()
                                            Text(chat.lastMessage)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                                .lineLimit(1)
                                        }

                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Hidden NavigationLink for pushing ChatView after NewChat
                    NavigationLink(
                        destination: selectedFriend.map { ChatView(otherUser: $0) },
                        isActive: $navigateToChat
                    ) {
                        EmptyView()
                    }
                    .hidden()
                }
            }
            .sheet(isPresented: $showNewChat) {
                NewChatView(selectedFriend: $selectedFriend, dismissSheet: {
                    showNewChat = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        navigateToChat = true
                    }
                })
            }
            .onAppear {
                startChatListeners()
            }
            .onDisappear {
                chatListeners.forEach { $0.remove() }
                chatListeners.removeAll()
            }
        }
    }

    func startChatListeners() {
        let db = Firestore.firestore()

        // Remove old listeners
        chatListeners.forEach { $0.remove() }
        chatListeners.removeAll()

        db.collection("chats")
            .whereField("participants", arrayContains: currentUID)
            .order(by: "lastUpdated", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let chatDocs = snapshot?.documents else { return }

                for doc in chatDocs {
                    let chatId = doc.documentID
                    let data = doc.data()
                    let lastMessage = data["lastMessage"] as? String ?? ""
                    let timestamp = data["lastUpdated"] as? Timestamp ?? Timestamp()
                    let participants = data["participants"] as? [String] ?? []

                    let otherUID = participants.first(where: { $0 != currentUID }) ?? ""

                    // Get other user's info
                    db.collection("users").document(otherUID).getDocument { userSnap, _ in
                        if let userData = userSnap?.data() {
                            let user = UserProfile(
                                uid: otherUID,
                                username: userData["username"] as? String ?? "",
                                profilePictureURL: URL(string: userData["photoURL"] as? String ?? ""),
                                hasBeenRequested: false
                            )

                            let preview = ChatPreview(
                                id: chatId,
                                user: user,
                                lastMessage: lastMessage,
                                timestamp: timestamp
                            )

                            DispatchQueue.main.async {
                                if let index = recentChats.firstIndex(where: { $0.id == chatId }) {
                                    recentChats[index] = preview
                                } else {
                                    recentChats.append(preview)
                                }
                            }
                        }
                    }

                    //Also listen to the most recent message (same as before, if still needed)
                    let listener = db.collection("chats")
                        .document(chatId)
                        .collection("messages")
                        .order(by: "timestamp", descending: true)
                        .limit(to: 1)
                        .addSnapshotListener { _, _ in }

                    chatListeners.append(listener)
                }
            }
    }
}

struct ChatPreview: Identifiable {
    let id: String
    let user: UserProfile
    let lastMessage: String
    let timestamp: Timestamp
}
