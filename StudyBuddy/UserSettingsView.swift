//
//  UserSettingsView.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/5/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

struct UserSettingsView: View {
    @Environment(\.dismiss) var dismiss

    @State private var profileImage: UIImage? = nil
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showImagePicker = false
    @State private var photoURL: URL? = UserDefaults.standard.url(forKey: "profileImageURL")

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var preferredName = ""
    @State private var username = ""
    @State private var bio = ""

    @State private var currentPassword = ""
    @State private var newPassword = ""

    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                Color.pink.opacity(0.1).edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(spacing: 20) {
                        Spacer().frame(height: 60)

                        Text("Edit Profile")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.pink)

                        Menu {
                            Button("Take Photo") {
                                imagePickerSource = .camera
                                showImagePicker = true
                            }
                            Button("Choose from Library") {
                                imagePickerSource = .photoLibrary
                                showImagePicker = true
                            }
                        } label: {
                            if let image = profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            } else if let url = photoURL {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image): image.resizable().scaledToFill()
                                    default:
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .foregroundColor(.pink)
                                    }
                                }
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .foregroundColor(.pink)
                            }
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.pink, lineWidth: 2))

                        Group {
                            labeledTextField("First Name:", text: $firstName)
                            labeledTextField("Last Name:", text: $lastName)
                            labeledTextField("Preferred Name (optional):", text: $preferredName)
                            labeledTextField("Username:", text: $username)
                            labeledTextField("Bio:", text: $bio, isMultiline: true)
                        }

                        Divider().padding(.horizontal)

                        Text("Update Password")
                            .font(.headline)
                            .foregroundColor(.pink)

                        Group {
                            labeledSecureField("Current Password:", text: $currentPassword)
                            labeledSecureField("New Password:", text: $newPassword)
                        }

                        if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.footnote)
                        }

                        if let success = successMessage {
                            Text(success)
                                .foregroundColor(.green)
                                .font(.footnote)
                        }

                        Button("Save Changes") {
                            saveChanges()
                        }
                        .padding()
                        .background(Color.pink)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)

                        Spacer()
                    }
                    .padding(.top)
                    .onAppear(perform: loadUserData)
                }
                .gesture(
                    TapGesture().onEnded {
                        hideKeyboard()
                    }
                )

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
        .fullScreenCover(isPresented: $showImagePicker) {
            ImagePicker(sourceType: imagePickerSource, image: $profileImage)
        }
    }

    func labeledTextField(_ label: String, text: Binding<String>, isMultiline: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.headline)
                .foregroundColor(.pink)
            if isMultiline {
                TextEditor(text: text)
                    .frame(height: 100)
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(10)
            } else {
                TextField(label, text: text)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal)
    }

    func labeledSecureField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.headline)
                .foregroundColor(.pink)
            SecureField(label, text: text)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
        }
        .padding(.horizontal)
    }

    func loadUserData() {
        guard let user = Auth.auth().currentUser else { return }
        Firestore.firestore().collection("users").document(user.uid).getDocument { snapshot, _ in
            if let data = snapshot?.data() {
                self.firstName = data["firstName"] as? String ?? ""
                self.lastName = data["lastName"] as? String ?? ""
                self.preferredName = data["preferredName"] as? String ?? ""
                self.username = data["username"] as? String ?? ""
                self.bio = data["bio"] as? String ?? ""
                if let urlString = data["photoURL"] as? String,
                   let url = URL(string: urlString) {
                    self.photoURL = url
                }
            }
        }
    }

    func saveChanges() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()

        db.collection("users").whereField("username", isEqualTo: username).getDocuments { snapshot, error in
            if let error = error {
                self.errorMessage = "Failed to check username: \(error.localizedDescription)"
                return
            }

            if let documents = snapshot?.documents, documents.contains(where: { $0.documentID != user.uid }) {
                self.errorMessage = "Username is already taken."
                return
            }

            if !currentPassword.isEmpty && !newPassword.isEmpty {
                guard let email = user.email else { return }

                let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
                user.reauthenticate(with: credential) { _, error in
                    if let error = error {
                        self.errorMessage = "Current password incorrect."
                        self.successMessage = nil
                        return
                    }

                    user.updatePassword(to: newPassword) { error in
                        if let error = error {
                            self.errorMessage = "Password update failed: \(error.localizedDescription)"
                            self.successMessage = nil
                        } else {
                            self.currentPassword = ""
                            self.newPassword = ""
                            updateProfile(user: user)
                        }
                    }
                }
            } else if currentPassword.isEmpty && newPassword.isEmpty {
                updateProfile(user: user)
            } else {
                self.errorMessage = "Please fill in both current and new password to update."
                self.successMessage = nil
            }
        }
    }

    func updateProfile(user: User) {
        let db = Firestore.firestore()

        var updateData: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "preferredName": preferredName,
            "username": username,
            "bio": bio
        ]

        func finalizeUpdate(with url: URL?) {
            if let url = url {
                updateData["photoURL"] = url.absoluteString
                UserDefaults.standard.set(url.absoluteString, forKey: "profileImageURL")
            }

            db.collection("users").document(user.uid).updateData(updateData) { err in
                if let err = err {
                    self.errorMessage = "Failed to update: \(err.localizedDescription)"
                    self.successMessage = nil
                } else {
                    self.successMessage = "Profile updated!"
                    self.errorMessage = nil
                    self.profileImage = nil
                    if let url = url {
                        self.photoURL = url 
                    }
                }
            }
        }

        if let image = profileImage {
            uploadProfileImage(image, for: user.uid, completion: finalizeUpdate)
        } else {
            finalizeUpdate(with: nil)
        }
    }

    func uploadProfileImage(_ image: UIImage, for uid: String, completion: @escaping (URL?) -> Void) {
        let storageRef = Storage.storage().reference().child("profilePics/\(uid)")
        guard let imageData = image.jpegData(compressionQuality: 0.4) else {
            completion(nil)
            return
        }

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        storageRef.putData(imageData, metadata: metadata) { _, error in
            if error != nil {
                completion(nil)
                return
            }

            storageRef.downloadURL { url, _ in
                completion(url)
            }
        }
    }
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
#endif
