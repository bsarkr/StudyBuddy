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
    @State private var goToVerification = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pink.opacity(0.1).edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    HStack {
                        Button(action: {
                            dismiss()
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
                    .navigationBarBackButtonHidden(true)
                    .navigationDestination(isPresented: $goToVerification) {
                        EmailVerificationView().environmentObject(authViewModel)
                    }

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
                            Circle()
                                .fill(Color.white)
                                .frame(width: 100, height: 100)
                                .overlay(Image(systemName: "person.crop.circle.fill.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundColor(.pink))
                                .shadow(radius: 2)
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
                .navigationDestination(isPresented: $goToVerification) {
                    EmailVerificationView().environmentObject(authViewModel)
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
                errorMessage = "Failed to create user."
                return
            }

            user.sendEmailVerification(completion: nil)

            var userData: [String: Any] = [
                "email": email,
                "firstName": firstName,
                "lastName": lastName,
                "setupComplete": true,
                "createdAt": Timestamp(date: Date())
            ]
            if !preferredName.isEmpty { userData["preferredName"] = preferredName }
            if !bio.isEmpty { userData["bio"] = bio }

            let db = Firestore.firestore()
            let uid = user.uid

            if let imageData = profileImage?.jpegData(compressionQuality: 0.7) {
                let ref = Storage.storage().reference().child("profilePictures/\(uid).jpg")
                ref.putData(imageData, metadata: nil) { _, error in
                    if error != nil {
                        errorMessage = "Image upload failed"
                        return
                    }

                    ref.downloadURL { url, _ in
                        if let downloadURL = url {
                            userData["photoURL"] = downloadURL.absoluteString
                        }
                        saveUserData(uid, userData)
                    }
                }
            } else {
                saveUserData(uid, userData)
            }
        }
    }

    func saveUserData(_ uid: String, _ userData: [String: Any]) {
        Firestore.firestore().collection("users").document(uid).setData(userData) { err in
            if err == nil {
                authViewModel.isLoggedIn = true
                authViewModel.hasCompletedSetup = true
                goToVerification = true
            } else {
                errorMessage = err?.localizedDescription
            }
        }
    }
}
