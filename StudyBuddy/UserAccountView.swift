//
//  UserAccountView.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 4/12/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

struct UserAccountView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var profileImage: UIImage? = nil
    @State private var selectedItem: PhotosPickerItem?
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var preferredName = ""
    @State private var bio = ""
    @State private var photoURL: URL? = nil
    @State private var errorMessage: String?
    @State private var showImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary

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
                        } else if let url = photoURL {
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
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.pink)
                        }
                    }

                    Text("Name: \(displayName)")
                        .font(.headline)

                    TextField("Bio", text: $bio)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .padding(.horizontal)

                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
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
                .id(UUID())
                .edgesIgnoringSafeArea(.all) // just in case
        }
        .onAppear(perform: loadUserData)
        .task {
            loadUserData()
        }
    }

    func loadUserData() {
        guard let user = Auth.auth().currentUser else { return }
        let docRef = Firestore.firestore().collection("users").document(user.uid)
        docRef.getDocument { snapshot, _ in
            if let data = snapshot?.data() {
                self.firstName = data["firstName"] as? String ?? ""
                self.lastName = data["lastName"] as? String ?? ""
                self.preferredName = data["preferredName"] as? String ?? ""
                self.bio = data["bio"] as? String ?? ""
                if let urlString = data["photoURL"] as? String,
                   let url = URL(string: urlString) {
                    self.photoURL = url
                    UserDefaults.standard.set(urlString, forKey: "profileImageURL")
                }
            }
        }
    }

    func saveChanges() {
        guard let user = Auth.auth().currentUser else { return }

        var updateData: [String: Any] = ["bio": bio]

        func completeUpdate(with url: URL?) {
            if let url = url {
                updateData["photoURL"] = url.absoluteString
                self.photoURL = url
                UserDefaults.standard.set(url.absoluteString, forKey: "profileImageURL")
            }

            Firestore.firestore().collection("users").document(user.uid).updateData(updateData) { error in
                if let error = error {
                    errorMessage = "Update failed: \(error.localizedDescription)"
                } else {
                    errorMessage = nil
                    profileImage = nil
                    loadUserData()
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
