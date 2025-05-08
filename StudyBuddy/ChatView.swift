//
//  ChatView.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/7/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine

enum ChatRenderItem: Identifiable {
    case message(index: Int, message: Message)
    case timestamp(Timestamp)

    var id: String {
        switch self {
        case .message(_, let msg): return "msg_\(msg.id)"
        case .timestamp(let ts): return "ts_\(ts.seconds)"
        }
    }
}

struct ChatView: View {
    let otherUser: UserProfile
    @Environment(\.dismiss) var dismiss
    @State private var messages: [Message] = []
    @State private var newMessage = ""
    @State private var chatListener: ListenerRegistration?

    @State private var fullName: String = ""
    @State private var profileURL: URL? = nil
    @State private var isKeyboardVisible: Bool = false
    @State private var inputHeight: CGFloat = 40

    @EnvironmentObject var authViewModel: AuthViewModel

    var currentUID: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    var chatId: String {
        [currentUID, otherUser.uid].sorted().joined(separator: "_")
    }

    func formattedDate(_ timestamp: Timestamp) -> String {
        let date = timestamp.dateValue()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d 'at' h:mm a"
        return formatter.string(from: date)
    }

    var body: some View {
        ZStack {
            Color.pink.opacity(0.05).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.pink)
                            .padding(10)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }

                    if let url = profileURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable().foregroundColor(.pink)
                            }
                        }
                        .frame(width: 45, height: 45)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.pink, lineWidth: 2))
                    }

                    Text(fullName.isEmpty ? otherUser.username : fullName)
                        .font(.title2).bold().foregroundColor(.pink)

                    Spacer()
                }
                .padding(.horizontal).padding(.top, 16).padding(.bottom, 8)

                Divider()

                // Messages
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        LazyVStack {
                            if messages.isEmpty {
                                Text("No messages yet.")
                                    .foregroundColor(.gray)
                                    .padding(.top, 40)
                            } else {
                                let renderItems = generateRenderItems()

                                ForEach(renderItems) { item in
                                    switch item {
                                    case .timestamp(let ts):
                                        Text(formattedDate(ts))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .padding(.vertical, 4)

                                    case .message(let index, let message):
                                        let isCurrentUser = message.senderId == currentUID
                                        let isLastInGroup = !isCurrentUser &&
                                            (index == messages.count - 1 || messages[index + 1].senderId == currentUID)

                                        HStack(alignment: .bottom, spacing: 8) {
                                            if !isCurrentUser {
                                                if isLastInGroup {
                                                    AsyncImage(url: profileURL) { phase in
                                                        switch phase {
                                                        case .success(let image):
                                                            image.resizable().scaledToFill()
                                                        default:
                                                            Image(systemName: "person.crop.circle.fill")
                                                                .resizable().foregroundColor(.pink)
                                                        }
                                                    }
                                                    .frame(width: 30, height: 30)
                                                    .clipShape(Circle())
                                                    .overlay(Circle().stroke(Color.pink, lineWidth: 1))
                                                } else {
                                                    Color.clear.frame(width: 30, height: 30)
                                                }
                                            }

                                            if isCurrentUser {
                                                Spacer()
                                                Text(message.text)
                                                    .padding()
                                                    .background(Color.pink)
                                                    .foregroundColor(.white)
                                                    .cornerRadius(16)
                                            } else {
                                                Text(message.text)
                                                    .padding()
                                                    .background(Color.white)
                                                    .cornerRadius(16)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 16)
                                                            .stroke(Color.pink.opacity(0.2), lineWidth: 1)
                                                    )
                                                Spacer()
                                            }
                                        }
                                        .padding(.horizontal)
                                        .id(message.id)
                                    }
                                }
                            }
                        }
                        .padding(.top).padding(.bottom, 24)
                    }
                    .onChange(of: messages.count) { _ in
                        if let last = messages.last {
                            withAnimation {
                                scrollProxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: isKeyboardVisible) { visible in
                        if visible, let last = messages.last {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                withAnimation {
                                    scrollProxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    .onReceive(Just(messages)) { _ in
                        if let last = messages.last {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    scrollProxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }

                Divider()

                // Input
                HStack(alignment: .bottom, spacing: 8) {
                    ZStack(alignment: .topLeading) {
                        if newMessage.isEmpty {
                            Text("Message...")
                                .foregroundColor(.gray)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 12)
                        }

                        GrowingTextEditor(text: $newMessage, height: $inputHeight)
                            .frame(height: inputHeight)
                            .background(Color.white)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }

                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.pink)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            loadMessages()
            loadFriendNameAndPhoto()
            markMessagesAsSeen()

            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
                isKeyboardVisible = true
            }
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                isKeyboardVisible = false
            }
        }
        .onDisappear {
            chatListener?.remove()
            NotificationCenter.default.removeObserver(self)
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    func generateRenderItems() -> [ChatRenderItem] {
        var items: [ChatRenderItem] = []
        var lastTimestamp: Timestamp? = nil

        for (index, message) in messages.enumerated() {
            let currentTimestamp = message.timestamp
            if lastTimestamp == nil || currentTimestamp.dateValue().timeIntervalSince(lastTimestamp!.dateValue()) > 300 {
                items.append(.timestamp(currentTimestamp))
            }
            items.append(.message(index: index, message: message))
            lastTimestamp = currentTimestamp
        }

        return items
    }

    func loadFriendNameAndPhoto() {
        Firestore.firestore().collection("users").document(otherUser.uid).getDocument { snapshot, _ in
            if let data = snapshot?.data() {
                let firstName = data["firstName"] as? String ?? ""
                let lastName = data["lastName"] as? String ?? ""
                let preferredName = data["preferredName"] as? String ?? ""
                let photo = data["photoURL"] as? String ?? ""
                fullName = preferredName.isEmpty ? "\(firstName) \(lastName)" : preferredName
                if let url = URL(string: photo) {
                    profileURL = url
                }
            }
        }
    }

    func loadMessages() {
        chatListener?.remove()
        self.messages = []

        let db = Firestore.firestore()
        chatListener = db.collection("chats")
            .document(chatId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error loading messages: \(error.localizedDescription)")
                    return
                }

                self.messages = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    return Message(
                        id: doc.documentID,
                        senderId: data["senderId"] as? String ?? "",
                        receiverId: data["receiverId"] as? String ?? "",
                        text: data["text"] as? String ?? "",
                        timestamp: data["timestamp"] as? Timestamp ?? Timestamp()
                    )
                } ?? []
            }
    }

    func sendMessage() {
        guard !newMessage.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let textToSend = newMessage
        newMessage = ""

        let db = Firestore.firestore()
        let chatRef = db.collection("chats").document(chatId)
        let messageRef = chatRef.collection("messages").document()
        let timestamp = Timestamp()

        let senderUsername: String
        if let user = authViewModel.currentUser {
            senderUsername = user.username
        } else {
            senderUsername = "You"
        }
        let lastMsgPreview = "\(senderUsername): \(textToSend)"

        chatRef.setData([
            "participants": [currentUID, otherUser.uid],
            "lastMessage": textToSend,
            "lastUpdated": timestamp,
            "lastSender": currentUID
        ], merge: true)

        let messageData: [String: Any] = [
            "senderId": currentUID,
            "receiverId": otherUser.uid,
            "text": textToSend,
            "timestamp": timestamp,
            "seen": false
        ]

        messageRef.setData(messageData)
    }

    func markMessagesAsSeen() {
        let db = Firestore.firestore()
        let messagesRef = db.collection("chats").document(chatId).collection("messages")

        messagesRef
            .whereField("receiverId", isEqualTo: currentUID)
            .whereField("seen", isEqualTo: false)
            .getDocuments { snapshot, _ in
                let batch = db.batch()
                snapshot?.documents.forEach { doc in
                    batch.updateData(["seen": true], forDocument: doc.reference)
                }
                batch.commit()
            }
    }
}
