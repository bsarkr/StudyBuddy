//
//  Homepage.swift
//  StudyBuddy
//  Created by Bilash Sarkar and Max Hazelton on 4/11/25.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct Homepage: View {
    @State private var userName: String = "User"
    @State private var sets: [URL] = []
    @State private var folders: [URL] = []
    @State private var searchText: String = ""
    @State private var preferredName: String? = nil
    @State private var firstName: String = "User"
    @EnvironmentObject var authViewModel: AuthViewModel

    let libraryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("library")

    var filteredSets: [URL] {
        searchText.isEmpty ? sets : sets.filter { $0.lastPathComponent.localizedCaseInsensitiveContains(searchText) }
    }

    var filteredFolders: [URL] {
        searchText.isEmpty ? folders : folders.filter { $0.lastPathComponent.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.pink.opacity(0.15).edgesIgnoringSafeArea(.all)

                VStack(spacing: 16) {

                    // Header
                    ZStack {
                        Color.pink
                            .edgesIgnoringSafeArea(.top)

                        HStack {
                            Text("Hello, \(preferredName ?? firstName)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            Spacer()

                            NavigationLink(destination: UserAccountView().environmentObject(authViewModel)) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 44, height: 44)
                                        .shadow(radius: 2)
                                    Text(String((preferredName ?? firstName).prefix(1)))
                                        .font(.headline)
                                        .foregroundColor(.pink)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .padding(.bottom, 10)
                    }
                    .frame(height: 40)
                    .padding(.bottom, 15)

                    // Search bar
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.pink)

                            TextField("Search sets or folders...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .foregroundColor(.pink)
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.pink.opacity(0.4), lineWidth: 1)
                        )
                        .shadow(color: Color.pink.opacity(0.2), radius: 2, x: 0, y: 2)
                    }
                    .padding(.horizontal)

                    // Sets
                    VStack(alignment: .leading, spacing: 8) {
                        Text("All Sets")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(.leading)
                            .padding(.top, 10)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                if filteredSets.isEmpty {
                                    Text("No sets created yet.")
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding()
                                        .background(Color.pink.opacity(0.4))
                                        .cornerRadius(10)
                                } else {
                                    ForEach(filteredSets, id: \.self) { setURL in
                                        Text(setURL.deletingPathExtension().lastPathComponent)
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Color.pink.opacity(0.6))
                                            .cornerRadius(12)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        Spacer()
                    }
                    .frame(height: 240)
                    .background(Color.pink.opacity(0.25))
                    .cornerRadius(20)
                    .padding(.bottom, 8)

                    // Folders
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Folders")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(.leading)
                            .padding(.top, 10)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                if filteredFolders.isEmpty {
                                    Text("No folders yet.")
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding()
                                        .background(Color.pink.opacity(0.4))
                                        .cornerRadius(10)
                                } else {
                                    ForEach(filteredFolders, id: \.self) { folderURL in
                                        Text(folderURL.lastPathComponent)
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Color.pink.opacity(0.5))
                                            .cornerRadius(12)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        Spacer()
                    }
                    .frame(height: 240)
                    .background(Color.pink.opacity(0.2))
                    .cornerRadius(20)

                    Spacer()

                    // Add Button
                    HStack {
                        Spacer()
                        Button(action: {
                            // Add new set action
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.pink)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding()
                    }
                }
                .onAppear {
                    createLibraryDirectoryIfNeeded()
                    fetchUserName()
                    loadFoldersAndSets()
                }
            }
            .navigationBarHidden(true)
        }
    }

    func createLibraryDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: libraryURL.path) {
            do {
                try FileManager.default.createDirectory(at: libraryURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Failed to create library directory: \(error)")
            }
        }
    }

    func loadFoldersAndSets() {
        var allSets: [URL] = []
        var allFolders: [URL] = []

        if let folderContents = try? FileManager.default.contentsOfDirectory(at: libraryURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
            for folder in folderContents where folder.hasDirectoryPath {
                allFolders.append(folder)

                if let setFiles = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
                    let txtFiles = setFiles.filter { $0.pathExtension == "txt" }
                    allSets.append(contentsOf: txtFiles)
                }
            }
        }

        self.folders = allFolders
        self.sets = allSets
    }

    func fetchUserName() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(user.uid)

        docRef.getDocument { snapshot, error in
            if let data = snapshot?.data() {
                self.firstName = data["firstName"] as? String ?? "User"
                self.preferredName = data["preferredName"] as? String
            }
        }
    }
}

struct Homepage_Previews: PreviewProvider {
    static var previews: some View {
        Homepage().environmentObject(AuthViewModel())
    }
}
