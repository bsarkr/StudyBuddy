//
//  UserPersonalView.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 4/14/25
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import PhotosUI

struct UserPersonalView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var profileImage: UIImage? = nil
    @State private var selectedItem: PhotosPickerItem?
    @State private var bio = ""
    @State private var username = ""
    @State private var errorMessage: String?
    @State private var goToHome = false
    @State private var isUsernameAvailable: Bool? = nil
    @State private var usernameCheckTask: DispatchWorkItem?
    @State private var checkingUsername = false

    @State private var showImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pink.opacity(0.1).edgesIgnoringSafeArea(.all)

                VStack(spacing: 24) {
                    Text("Personalize Your Profile")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.pink)

                    Menu {
                        Button("Take Photo") {
                            imagePickerSource = .camera
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showImagePicker = true
                            }
                        }
                        Button("Choose from Library") {
                            imagePickerSource = .photoLibrary
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showImagePicker = true
                            }
                        }
                    } label: {
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
                    .fullScreenCover(isPresented: $showImagePicker) {
                        ImagePicker(sourceType: imagePickerSource, image: $profileImage)
                            .id(UUID())
                            .edgesIgnoringSafeArea(.all)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Username*", text: $username)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: username) { _ in
                                debounceUsernameCheck()
                            }

                        if checkingUsername {
                            Text("Checking username availability...")
                                .font(.caption)
                                .foregroundColor(.orange)
                        } else if let available = isUsernameAvailable {
                            Text(available ? "✅ Username available" : "❌ Username taken")
                                .font(.caption)
                                .foregroundColor(available ? .green : .red)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.horizontal)

                    TextField("Bio (optional)", text: $bio)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .padding(.horizontal)

                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                    }

                    Button("Finish") {
                        saveUserData()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.pink)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)

                    Spacer()
                }
                .padding()
                .navigationBarBackButtonHidden(true)
            }
            .fullScreenCover(isPresented: $goToHome) {
                Homepage().environmentObject(authViewModel)
            }
        }
    }

    func debounceUsernameCheck() {
        usernameCheckTask?.cancel()

        let task = DispatchWorkItem {
            checkUsernameAvailability(username)
        }

        usernameCheckTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)
    }

    func checkUsernameAvailability(_ username: String) {
        checkingUsername = true
        let db = Firestore.firestore()
        db.collection("users")
            .whereField("username", isEqualTo: username)
            .getDocuments { snapshot, error in
                checkingUsername = false

                if let error = error {
                    print("Username check error: \(error.localizedDescription)")
                    isUsernameAvailable = nil
                    return
                }

                guard let snapshot = snapshot else {
                    isUsernameAvailable = nil
                    return
                }

                let taken = snapshot.documents.contains {
                    let theirUsername = $0.get("username") as? String
                    return theirUsername?.lowercased() == username.lowercased()
                }

                isUsernameAvailable = !taken
            }
    }

    func saveUserData() {
        guard let user = Auth.auth().currentUser else { return }

        guard !username.isEmpty else {
            errorMessage = "Username is required."
            return
        }

        if checkingUsername {
            errorMessage = "Still checking username availability. Please wait."
            return
        }

        guard isUsernameAvailable == true else {
            errorMessage = "Please choose a unique username."
            return
        }

        let uid = user.uid
        var updateData: [String: Any] = ["username": username]

        if !bio.isEmpty {
            updateData["bio"] = bio
        }

        func completeUpdate(with url: URL?) {
            if let url = url {
                updateData["photoURL"] = url.absoluteString
                UserDefaults.standard.set(url.absoluteString, forKey: "profileImageURL")
            }

            Firestore.firestore().collection("users").document(uid).updateData(updateData) { error in
                if let error = error {
                    errorMessage = "Failed to update data: \(error.localizedDescription)"
                    return
                }

                DispatchQueue.main.async {
                    authViewModel.hasCompletedSetup = true
                    goToHome = true
                }
            }
        }

        if let image = profileImage {
            uploadProfileImage(image) { result in
                switch result {
                case .success(let url):
                    completeUpdate(with: url)
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        } else {
            completeUpdate(with: nil)
        }
    }

    func uploadProfileImage(_ image: UIImage, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "No user ID", code: 1)))
            return
        }

        let storageRef = Storage.storage().reference().child("profilePics/\(uid)")
        guard let imageData = image.jpegData(compressionQuality: 0.4) else {
            completion(.failure(NSError(domain: "Image compression failed", code: 2)))
            return
        }

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        storageRef.putData(imageData, metadata: metadata) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url))
                }
            }
        }
    }
}
