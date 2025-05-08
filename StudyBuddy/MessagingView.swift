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
                            let filteredChats = recentChats
                                .filter { searchText.isEmpty || $0.user.username.lowercased().contains(searchText.lowercased()) }
                                .sorted { $0.timestamp > $1.timestamp }

                            ForEach(filteredChats) { chat in
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

                                        if chat.hasUnread {
                                            Circle()
                                                .fill(Color.red)
                                                .frame(width: 10, height: 10)
                                        }
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

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
                loadChatPreviewsFromCache()
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
        chatListeners.forEach { $0.remove() }
        chatListeners.removeAll()

        db.collection("chats")
            .whereField("participants", arrayContains: currentUID)
            .order(by: "lastUpdated", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let chatDocs = snapshot?.documents else { return }

                var updatedChats: [ChatPreview] = []
                let group = DispatchGroup()

                for doc in chatDocs {
                    let chatId = doc.documentID
                    let data = doc.data()
                    let participants = data["participants"] as? [String] ?? []
                    let timestamp = data["lastUpdated"] as? Timestamp ?? Timestamp()

                    guard let otherUID = participants.first(where: { $0 != currentUID }) else { continue }

                    group.enter()

                    db.collection("users").document(otherUID).getDocument { userSnap, _ in
                        guard let userData = userSnap?.data() else {
                            group.leave()
                            return
                        }

                        let user = UserProfile(
                            uid: otherUID,
                            username: userData["username"] as? String ?? "",
                            profilePictureURL: URL(string: userData["photoURL"] as? String ?? ""),
                            hasBeenRequested: false
                        )

                        // Get the most recent message
                        db.collection("chats").document(chatId)
                            .collection("messages")
                            .order(by: "timestamp", descending: true)
                            .limit(to: 1)
                            .getDocuments { messageSnap, _ in
                                let lastMessageDoc = messageSnap?.documents.first
                                let messageText = lastMessageDoc?["text"] as? String ?? ""
                                let messageSender = lastMessageDoc?["senderId"] as? String ?? ""

                                let prefix = messageSender == currentUID ? "" : "\(user.username): "
                                let previewText = prefix + messageText

                                db.collection("chats").document(chatId)
                                    .collection("messages")
                                    .whereField("receiverId", isEqualTo: currentUID)
                                    .whereField("seen", isEqualTo: false)
                                    .getDocuments { unreadSnap, _ in
                                        let hasUnread = messageSender != currentUID && (unreadSnap?.documents.count ?? 0) > 0

                                        let preview = ChatPreview(
                                            id: chatId,
                                            user: user,
                                            lastMessage: previewText,
                                            timestamp: timestamp,
                                            hasUnread: hasUnread
                                        )

                                        updatedChats.append(preview)
                                        group.leave()
                                    }
                            }
                    }
                }

                group.notify(queue: .main) {
                    self.recentChats = updatedChats
                    saveChatPreviewsToCache(updatedChats)
                }
            }
    }

    func saveChatPreviewsToCache(_ previews: [ChatPreview]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .secondsSince1970
            let data = try encoder.encode(previews)
            UserDefaults.standard.set(data, forKey: "cachedChatPreviews")
        } catch {
            print("Failed to encode and save chat previews: \(error)")
        }
    }

    func loadChatPreviewsFromCache() {
        guard let data = UserDefaults.standard.data(forKey: "cachedChatPreviews") else { return }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            let previews = try decoder.decode([ChatPreview].self, from: data)
            self.recentChats = previews
        } catch {
            print("Failed to load cached chat previews: \(error)")
        }
    }
}

struct ChatPreview: Identifiable, Codable {
    let id: String
    let user: UserProfile
    let lastMessage: String
    let timestamp: Date
    let hasUnread: Bool

    enum CodingKeys: String, CodingKey {
        case id, user, lastMessage, timestamp, hasUnread
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        user = try container.decode(UserProfile.self, forKey: .user)
        lastMessage = try container.decode(String.self, forKey: .lastMessage)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        hasUnread = try container.decode(Bool.self, forKey: .hasUnread)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(user, forKey: .user)
        try container.encode(lastMessage, forKey: .lastMessage)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(hasUnread, forKey: .hasUnread)
    }

    init(id: String, user: UserProfile, lastMessage: String, timestamp: Timestamp, hasUnread: Bool) {
        self.id = id
        self.user = user
        self.lastMessage = lastMessage
        self.timestamp = timestamp.dateValue()
        self.hasUnread = hasUnread
    }
}
