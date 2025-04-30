//
// homepage.swift
// StudyBuddy
//
// Created by Bilash Sarkar and Max Hazelton on 4/10/25


import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct Homepage: View {
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var sets: [URL] = []
    @State private var folders: [URL] = []
    @State private var searchText: String = ""
    @State private var preferredName: String? = nil
    @State private var firstName: String = "User"
    @State private var profileImageURL: String? = UserDefaults.standard.string(forKey: "profileImageURL")
    @State private var showingCreateSet = false

    @StateObject private var setViewModel = SetViewModel()

    let libraryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("library")

    var displayName: String {
        if let preferred = preferredName, !preferred.isEmpty {
            return preferred
        } else {
            return firstName
        }
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                Color.pink.opacity(0.15).edgesIgnoringSafeArea(.all)

                VStack(alignment: .leading, spacing: 10) {
                    
                    ZStack(alignment: .bottom) {
                        Color.pink
                            .ignoresSafeArea(edges: .top)

                        HStack {
                            Text("Hello, \(displayName)")
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(.white)
                            Spacer()
                            NavigationLink(destination: UserAccountView().environmentObject(authViewModel)) {
                                ZStack {
                                    if let urlString = profileImageURL, let url = URL(string: urlString) {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .empty:
                                                ProgressView()
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 55, height: 55)
                                                    .clipShape(Circle())
                                                    .overlay(Circle().stroke(Color.pink.opacity(0.4), lineWidth: 2))
                                            case .failure:
                                                placeholderCircle
                                            @unknown default:
                                                placeholderCircle
                                            }
                                        }
                                    } else {
                                        placeholderCircle
                                    }
                                }
                                .shadow(radius: 2)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 50) // for notch
                        .padding(.bottom, 10)
                    }
                    .frame(height: 20) // 🔥 Shorter height now
                    .background(Color.pink)

                    //Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.pink)
                        TextField("Search sets or folders...", text: $searchText)
                            .foregroundColor(.pink)
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.pink.opacity(0.4), lineWidth: 1))
                    .padding(.horizontal)
                    .padding(.top, 45)

                    // Main Content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                                
                                // 🟰 All Sets Section 🟰
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("All Sets")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .padding(.bottom, 5)

                                    if setViewModel.sets.isEmpty {
                                        Text("No sets yet.")
                                            .foregroundColor(.white.opacity(0.7))
                                            .padding()
                                            .background(Color.pink.opacity(0.4))
                                            .cornerRadius(10)
                                    } else {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 16) {
                                                ForEach(setViewModel.sets.filter {
                                                    searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText)
                                                }) { set in
                                                    VStack(alignment: .leading, spacing: 5) {
                                                        Text(set.title)
                                                            .font(.headline)
                                                            .foregroundColor(.white)
                                                        Text("\(set.terms.count) terms")
                                                            .font(.subheadline)
                                                            .foregroundColor(.white.opacity(0.7))
                                                    }
                                                    .padding()
                                                    .background(Color.pink.opacity(0.8))
                                                    .cornerRadius(16)
                                                }
                                            }
                                            .padding(.horizontal)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(20)
                                .frame(maxWidth: .infinity, alignment: .topLeading) //force top-left inside background
                                .frame(minHeight: 225)
                                .background(Color(red: 1.0, green: 0.7, blue: 0.7))
                                .cornerRadius(20)
                                .padding(.horizontal)

                                // -Folders Section-
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Folders")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .padding(.bottom, 5)

                                    if folders.isEmpty {
                                        Text("No folders yet.")
                                            .foregroundColor(.white.opacity(0.7))
                                            .padding()
                                            .background(Color.pink.opacity(0.4))
                                            .cornerRadius(10)
                                    } else {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 16) {
                                                ForEach(filteredFolders.map { $0.lastPathComponent }, id: \.self) { folder in
                                                    Text(folder)
                                                        .foregroundColor(.white)
                                                        .padding()
                                                        .background(Color.pink.opacity(0.6))
                                                        .cornerRadius(12)
                                                }
                                            }
                                            .padding(.horizontal)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(20)
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                                .frame(minHeight: 225)
                                .background(Color(red: 1.0, green: 0.7, blue: 0.7))
                                .cornerRadius(20)
                                .padding(.horizontal)
                            }
                            .padding(.top)
                        }
                }
                .sheet(isPresented: $showingCreateSet) {
                    CreateSetView(viewModel: setViewModel)
                }
                .onAppear {
                    createLibraryDirectoryIfNeeded()
                    fetchUserData()
                    loadFoldersAndSets()
                    if let uid = Auth.auth().currentUser?.uid {
                        setViewModel.fetchSets(for: uid)
                    }
                }
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .active {
                        fetchUserData()
                        if let uid = Auth.auth().currentUser?.uid {
                            setViewModel.fetchSets(for: uid)
                        }
                    }
                }
                // ➕ Floating + Button
                Button(action: {
                    showingCreateSet = true
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
            .navigationBarHidden(true)
        }
    }

    // Profile Image View
    var profileImage: some View {
        ZStack {
            if let urlString = profileImageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.pink.opacity(0.4), lineWidth: 2))
                    case .failure:
                        placeholderCircle
                    @unknown default:
                        placeholderCircle
                    }
                }
            } else {
                placeholderCircle
            }
        }
        .frame(width: 44, height: 44)
        .shadow(radius: 2)
    }

    var placeholderCircle: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 44, height: 44)
            .overlay(
                Text(String(displayName.prefix(1)))
                    .font(.headline)
                    .foregroundColor(.pink)
            )
    }

    var filteredFolders: [URL] {
        searchText.isEmpty ? folders : folders.filter { $0.lastPathComponent.localizedCaseInsensitiveContains(searchText) }
    }

    func fetchUserData() {
        guard let user = Auth.auth().currentUser else { return }
        let docRef = Firestore.firestore().collection("users").document(user.uid)
        docRef.getDocument { snapshot, _ in
            if let data = snapshot?.data() {
                self.firstName = data["firstName"] as? String ?? "User"
                self.preferredName = data["preferredName"] as? String
                if let url = data["photoURL"] as? String {
                    self.profileImageURL = url
                    UserDefaults.standard.set(url, forKey: "profileImageURL")
                }
            }
        }
    }

    func createLibraryDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: libraryURL.path) {
            try? FileManager.default.createDirectory(at: libraryURL, withIntermediateDirectories: true)
        }
    }

    func loadFoldersAndSets() {
        var allSets: [URL] = []
        var allFolders: [URL] = []

        if let contents = try? FileManager.default.contentsOfDirectory(at: libraryURL, includingPropertiesForKeys: nil) {
            for folder in contents where folder.hasDirectoryPath {
                allFolders.append(folder)
                if let setFiles = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) {
                    allSets.append(contentsOf: setFiles.filter { $0.pathExtension == "txt" })
                }
            }
        }

        self.folders = allFolders
        self.sets = allSets
    }
}


struct Homepage_Previews: PreviewProvider {
    static var previews: some View {
        Homepage()
            .environmentObject(AuthViewModel())
    }
}



