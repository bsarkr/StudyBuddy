//
//  UserAccountView.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 4/12/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct UserAccountView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var preferredName = ""
    @State private var username = ""
    @State private var bio = ""
    @State private var photoURL: URL? = UserDefaults.standard.url(forKey: "profileImageURL")
    @State private var navigateToSettings = false

    var displayName: String {
        preferredName.isEmpty ? "\(firstName) \(lastName)" : preferredName
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                Color.pink.opacity(0.1).edgesIgnoringSafeArea(.all)

                VStack(spacing: 24) {
                    Spacer().frame(height: 60)

                    Text("Your Profile")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.pink)

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
                        .overlay(Circle().stroke(Color.pink, lineWidth: 2))
                    }

                    Text("Name: \(displayName)")
                        .font(.headline)

                    Text("Username: @\(username)")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .frame(height: 100)
                            .shadow(radius: 1)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bio")
                                .font(.headline) // bigger and cleaner
                                .foregroundColor(.pink)
                                .padding(.top, 10)
                                .padding(.horizontal, 12)

                            Text(bio.isEmpty ? "No bio set." : bio)
                                .font(.body)
                                .foregroundColor(.black)
                                .padding(.horizontal, 12)
                        }
                    }
                    .padding(.horizontal)

                    NavigationLink("Settings", destination: UserSettingsView())
                        .padding()
                        .background(Color.pink)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.top)

                    Spacer()

                    Button(action: {
                        withAnimation {
                            authViewModel.signOut()
                            dismiss()
                        }
                    }) {
                        Text("Log Out")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .shadow(color: Color.red.opacity(0.3), radius: 4, x: 0, y: 3)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 25)
                }
                .padding(.top)
                .onAppear(perform: loadUserData)

                Button(action: {
                    withAnimation {
                        dismiss()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.pink)
                        .padding(10)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                .padding(.leading, 16)
                .padding(.top, 16)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    func loadUserData() {
        guard let user = Auth.auth().currentUser else { return }

        Firestore.firestore().collection("users").document(user.uid).getDocument { snapshot, _ in
            if let data = snapshot?.data() {
                self.firstName = data["firstName"] as? String ?? ""
                self.lastName = data["lastName"] as? String ?? ""
                self.preferredName = data["preferredName"] as? String ?? ""
                self.bio = data["bio"] as? String ?? ""
                self.username = data["username"] as? String ?? ""
                if let urlString = data["photoURL"] as? String,
                   let url = URL(string: urlString) {
                    self.photoURL = url
                    UserDefaults.standard.set(urlString, forKey: "profileImageURL")
                }
            }
        }
    }
}
