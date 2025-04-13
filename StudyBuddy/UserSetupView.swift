//
//  UserSetupView.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 4/12/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

struct UserSetupView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    let email: String
    let password: String

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var preferredName = ""
    @State private var bio = ""
    @State private var profileImage: UIImage? = nil
    @State private var selectedItem: PhotosPickerItem?
    @State private var errorMessage: String?
    @State private var navigateToVerification = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pink.opacity(0.1).edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    HStack {
                        Button(action: {
                            cancelAndDelete()
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.pink)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    Text("Tell us about you")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.pink)

                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        if let image = profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.pink, lineWidth: 2))
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 100, height: 100)
                                    .shadow(radius: 2)
                                Image(systemName: "person.crop.circle.fill.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundColor(.pink)
                            }
                        }
                    }
                    .task(id: selectedItem) {
                        if let data = try? await selectedItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            profileImage = uiImage
                        }
                    }

                    Group {
                        TextField("First Name*", text: $firstName)
                        TextField("Last Name*", text: $lastName)
                        TextField("Preferred Name (optional)", text: $preferredName)
                        TextField("Bio (optional)", text: $bio)
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(10)
                    .shadow(radius: 1)
                    .padding(.horizontal)

                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                    }

                    Button(action: submitUserInfo) {
                        Text("Finish Setup")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.pink)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .shadow(radius: 3)
                    }

                    Spacer()
                }
                .padding(.top)
                .navigationBarBackButtonHidden(true)

                NavigationLink(destination: EmailVerificationView(email: email).environmentObject(authViewModel), isActive: $navigateToVerification) {
                    EmptyView()
                }
            }
        }
    }

    func submitUserInfo() {
        guard !firstName.isEmpty, !lastName.isEmpty else {
            errorMessage = "Please enter your first and last name."
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }

            guard let user = result?.user else {
                errorMessage = "User creation failed."
                return
            }

            user.sendEmailVerification()

            var userData: [String: Any] = [
                "email": email,
                "firstName": firstName,
                "lastName": lastName,
                "setupComplete": true,
                "createdAt": Timestamp()
            ]
            if !preferredName.isEmpty { userData["preferredName"] = preferredName }
            if !bio.isEmpty { userData["bio"] = bio }

            if let imageData = profileImage?.jpegData(compressionQuality: 0.7) {
                let storage = Storage.storage()
                let ref = storage.reference().child("profilePictures/\(user.uid).jpg")
                let uploadTask = ref.putData(imageData, metadata: nil)

                uploadTask.observe(.success) { _ in
                    ref.downloadURL { url, _ in
                        if let url = url {
                            userData["photoURL"] = url.absoluteString
                        }
                        saveUserData(uid: user.uid, data: userData)
                    }
                }

                uploadTask.observe(.failure) { snapshot in
                    if let error = snapshot.error {
                        errorMessage = "Upload error: \(error.localizedDescription)"
                    }
                }
            } else {
                saveUserData(uid: user.uid, data: userData)
            }
        }
    }

    func saveUserData(uid: String, data: [String: Any]) {
        Firestore.firestore().collection("users").document(uid).setData(data) { error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                withAnimation {
                    authViewModel.isLoggedIn = true
                    authViewModel.hasCompletedSetup = true
                    authViewModel.isEmailVerified = false
                    navigateToVerification = true
                }
            }
        }
    }

    func cancelAndDelete() {
        guard let user = Auth.auth().currentUser else {
            dismiss()
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(user.uid).delete { _ in
            user.delete { _ in
                try? Auth.auth().signOut()
                authViewModel.isLoggedIn = false
                authViewModel.hasCompletedSetup = false
                authViewModel.isEmailVerified = false
                dismiss()
            }
        }
    }
}
