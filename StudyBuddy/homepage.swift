//  Homepage.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar and Max Hazelton on 4/10/25.

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
    @State private var showingAddOptions = false
    @State private var selectedTab = "home"
    @State private var showCreateFolderView = false

    @State private var firebaseFolders: [StudyFolder] = []

    @StateObject private var setViewModel = SetViewModel()

    let libraryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("library")

    var displayName: String {
        preferredName?.isEmpty == false ? preferredName! : firstName
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.pink.opacity(0.15).ignoresSafeArea()

                VStack(spacing: 0) {
                    if selectedTab == "folder" {
                        LibraryView()
                            .environmentObject(authViewModel)
                    } else if selectedTab == "friends" {
                        SocialView()
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            ZStack(alignment: .bottom) {
                                Color.pink.ignoresSafeArea(edges: .top)

                                HStack {
                                    Text("Hello, \(displayName)")
                                        .font(.largeTitle)
                                        .bold()
                                        .foregroundColor(.white)
                                    Spacer()
                                    NavigationLink(destination: UserAccountView().environmentObject(authViewModel)) {
                                        profileImage
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.top, 30)
                                .padding(.bottom, 10)
                            }
                            .frame(height: 50)

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
                            .padding(.top, 25)

                            ScrollView {
                                VStack(alignment: .leading, spacing: 20) {
                                    // Sets Section
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("All Sets")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                            .padding(.bottom, 5)

                                        let filteredSets = setViewModel.sets.filter {
                                            searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText)
                                        }

                                        if filteredSets.isEmpty {
                                            Text("No sets yet.")
                                                .foregroundColor(.white.opacity(0.7))
                                                .padding()
                                                .background(Color.pink.opacity(0.4))
                                                .cornerRadius(10)
                                        } else {
                                            ScrollView(.horizontal, showsIndicators: false) {
                                                LazyHGrid(rows: [GridItem(.fixed(80)), GridItem(.fixed(80))], spacing: 16) {
                                                    ForEach(filteredSets, id: \.id) { set in
                                                        NavigationLink(destination: SetDetailView(set: set).environmentObject(setViewModel)) {
                                                            VStack(alignment: .leading, spacing: 5) {
                                                                Text(set.title)
                                                                    .font(.headline)
                                                                    .foregroundColor(.white)
                                                                    .lineLimit(1)
                                                                    .truncationMode(.tail)
                                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                                Text("\(set.terms.count) terms")
                                                                    .font(.subheadline)
                                                                    .foregroundColor(.white.opacity(0.7))
                                                            }
                                                            .padding()
                                                            .frame(width: 150)
                                                            .background(Color.pink.opacity(0.7))
                                                            .cornerRadius(16)
                                                        }
                                                    }
                                                }
                                                .padding(.horizontal, 10)
                                            }
                                            .frame(height: 180)
                                        }
                                        Spacer()
                                    }
                                    .padding(20)
                                    .frame(maxWidth: .infinity, alignment: .topLeading)
                                    .frame(minHeight: 225)
                                    .background(Color(red: 1.0, green: 0.7, blue: 0.7))
                                    .cornerRadius(20)
                                    .padding(.horizontal)

                                    // Folders Section
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Folders")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                            .padding(.bottom, 5)

                                        let filteredFolders = firebaseFolders.filter {
                                            searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
                                        }

                                        if filteredFolders.isEmpty {
                                            Text("No folders yet.")
                                                .foregroundColor(.white.opacity(0.7))
                                                .padding()
                                                .background(Color.pink.opacity(0.4))
                                                .cornerRadius(10)
                                        } else {
                                            ScrollView(.horizontal, showsIndicators: false) {
                                                LazyHGrid(rows: [GridItem(.fixed(80)), GridItem(.fixed(80))], spacing: 16) {
                                                    ForEach(filteredFolders, id: \.id) { folder in
                                                        let totalTerms = folder.setIDs.reduce(0) { count, setID in
                                                            count + (setViewModel.sets.first { $0.id == setID }?.terms.count ?? 0)
                                                        }

                                                        NavigationLink(destination: FolderDetailView(folder: folder).environmentObject(setViewModel)) {
                                                            VStack(alignment: .leading, spacing: 4) {
                                                                Text(folder.name)
                                                                    .font(.body)
                                                                    .foregroundColor(.white)
                                                                    .lineLimit(1)
                                                                Text("\(totalTerms) terms")
                                                                    .font(.subheadline)
                                                                    .foregroundColor(.white.opacity(0.8))
                                                            }
                                                            .padding()
                                                            .frame(width: 150, alignment: .leading)
                                                            .background(Color.purple.opacity(0.7))
                                                            .cornerRadius(12)
                                                        }
                                                    }
                                                }
                                                .padding(.horizontal, 10)
                                            }
                                            .frame(height: 180)
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
                                .padding(.bottom, 80)
                            }
                        }
                    }
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        tabBarItem(icon: "house.fill", tag: "home")
                        Spacer()
                        Button(action: {
                            showingAddOptions = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.pink)
                                    .frame(width: 50, height: 50)
                                Image(systemName: "plus")
                                    .foregroundColor(.white)
                                    .font(.system(size: 22, weight: .bold))
                            }
                            .shadow(radius: 3)
                        }
                        Spacer()
                        tabBarItem(icon: "folder.fill", tag: "folder")
                        Spacer()
                        tabBarItem(icon: "person.2.fill", tag: "friends")
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.95))
                }
            }
            .navigationBarHidden(true)
            .onTapGesture {
                UIApplication.shared.endEditing()
            }
        }
        .fullScreenCover(isPresented: $showingCreateSet) {
            CreateSetView(viewModel: setViewModel)
        }
        .fullScreenCover(isPresented: $showCreateFolderView, onDismiss: {
            if let uid = Auth.auth().currentUser?.uid {
                fetchStudyFolders(for: uid)
            }
        }) {
            CreateFolderView(setViewModel: setViewModel)
        }
        .sheet(isPresented: $showingAddOptions) {
            CreateOptionsSheet(
                onCreateSet: {
                    showingAddOptions = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingCreateSet = true
                    }
                },
                onCreateFolder: {
                    showingAddOptions = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showCreateFolderView = true
                    }
                }
            )
            .background(.clear)
            .presentationDetents([.height(250)])
        }
        .onAppear {
            createLibraryDirectoryIfNeeded()
            fetchUserData()
            loadFoldersAndSets()
            if let uid = Auth.auth().currentUser?.uid {
                setViewModel.fetchSets(for: uid)
                fetchStudyFolders(for: uid)
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                fetchUserData()
                if let uid = Auth.auth().currentUser?.uid {
                    setViewModel.fetchSets(for: uid)
                    fetchStudyFolders(for: uid)
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    func fetchStudyFolders(for uid: String) {
        Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("folders")
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents, error == nil else { return }
                let fetched = documents.compactMap { doc -> StudyFolder? in
                    StudyFolder(id: doc.documentID, data: doc.data())
                }
                self.firebaseFolders = fetched
            }
    }

    func tabBarItem(icon: String, tag: String) -> some View {
        Button(action: { selectedTab = tag }) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(selectedTab == tag ? .pink : .gray)
        }
    }

    var profileImage: some View {
        ZStack {
            if let urlString = profileImageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image.resizable()
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
        .frame(width: 55, height: 55)
        .shadow(radius: 2)
    }

    var placeholderCircle: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 44, height: 44)
            .overlay(Text(String(displayName.prefix(1))).font(.headline).foregroundColor(.pink))
    }

    var filteredFolders: [URL] {
        searchText.isEmpty ? folders : folders.filter {
            $0.lastPathComponent.localizedCaseInsensitiveContains(searchText)
        }
    }

    func fetchUserData() {
        guard let user = Auth.auth().currentUser else { return }
        Firestore.firestore().collection("users").document(user.uid).getDocument { snapshot, _ in
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
