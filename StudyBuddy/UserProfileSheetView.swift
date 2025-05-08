//
//  UserProfileSheetView.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/7/25.
//

import SwiftUI
import FirebaseFirestore

struct UserProfileSheetView: View {
    let userID: String
    @Environment(\.dismiss) var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var preferredName = ""
    @State private var username = ""
    @State private var bio = ""
    @State private var photoURL: URL?

    var displayName: String {
        preferredName.isEmpty ? "\(firstName) \(lastName)" : preferredName
    }

    var body: some View {
        ZStack {
            Color(red: 1.0, green: 0.93, blue: 0.95).ignoresSafeArea()

            VStack(spacing: 24) {
                if let url = photoURL {
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
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.pink, lineWidth: 3))
                }

                Text(displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)

                Text("@\(username)")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Bio")
                        .font(.headline)
                        .foregroundColor(.pink)

                    Text(bio.isEmpty ? "No bio set." : bio)
                        .font(.body)
                        .foregroundColor(.black)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 30)
            .padding(.bottom, 20)
        }
        .onAppear(perform: loadUserData)
    }

    func loadUserData() {
        Firestore.firestore().collection("users").document(userID).getDocument { snapshot, _ in
            if let data = snapshot?.data() {
                firstName = data["firstName"] as? String ?? ""
                lastName = data["lastName"] as? String ?? ""
                preferredName = data["preferredName"] as? String ?? ""
                username = data["username"] as? String ?? ""
                bio = data["bio"] as? String ?? ""
                if let urlString = data["photoURL"] as? String {
                    photoURL = URL(string: urlString)
                }
            }
        }
    }
}
