//
//  ChatView.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/7/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ChatView: View {
    let otherUser: UserProfile
    @Environment(\.dismiss) var dismiss
    @State private var messages: [Message] = []
    @State private var newMessage = ""
    @State private var chatListener: ListenerRegistration?

    @State private var fullName: String = ""
    @State private var profileURL: URL? = nil

    var currentUID: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    var chatId: String {
        [currentUID, otherUser.uid].sorted().joined(separator: "_")
    }

    var body: some View {
        ZStack {
            Color.pink.opacity(0.05).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header Row with Back, Image, Name
                HStack(spacing: 12) {
                    Button(action: {
                        dismiss()
                    }) {
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
                                    .resizable()
                                    .foregroundColor(.pink)
                            }
                        }
                        .frame(width: 45, height: 45)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.pink, lineWidth: 2))
                    }

                    Text(fullName.isEmpty ? otherUser.username : fullName)
                        .font(.title2)
                        .bold()
                        .foregroundColor(.pink)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)

                Divider()

                // Messages
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        LazyVStack {
                            ForEach(messages) { message in
                                HStack {
                                    if message.senderId == currentUID {
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
                        .padding(.top)
                    }
                    .onChange(of: messages.count) { _ in
                        if let last = messages.last {
                            withAnimation {
                                scrollProxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Message input
                HStack {
                    TextField("Message...", text: $newMessage)
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(16)

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
        }
        .onDisappear {
            chatListener?.remove()
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
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
        let db = Firestore.firestore()
        chatListener = db.collection("chats")
            .document(chatId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documents else { return }
                messages = docs.compactMap { doc in
                    let data = doc.data()
                    return Message(
                        id: doc.documentID,
                        senderId: data["senderId"] as? String ?? "",
                        receiverId: data["receiverId"] as? String ?? "",
                        text: data["text"] as? String ?? "",
                        timestamp: data["timestamp"] as? Timestamp ?? Timestamp()
                    )
                }
            }
    }

    func sendMessage() {
        guard !newMessage.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let textToSend = newMessage
        newMessage = ""

        let db = Firestore.firestore()
        let chatRef = db.collection("chats").document(chatId)
        let messageRef = chatRef.collection("messages").document()

        let messageData: [String: Any] = [
            "senderId": currentUID,
            "receiverId": otherUser.uid,
            "text": textToSend,
            "timestamp": Timestamp()
        ]

        // Save the message
        messageRef.setData(messageData) { error in
            if let error = error {
                print("Error sending message: \(error.localizedDescription)")
                newMessage = textToSend // restore input on failure
            } else {
                chatRef.setData([
                    "lastMessage": textToSend,
                    "lastUpdated": Timestamp(),
                    "participants": [currentUID, otherUser.uid]
                ], merge: true)
            }
        }
    }
}
