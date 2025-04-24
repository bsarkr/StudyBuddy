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
            ZStack {
                Color.pink.opacity(0.15).edgesIgnoringSafeArea(.all)

                VStack(spacing: 16) {
                    // Header
                    ZStack {
                        Color.pink.edgesIgnoringSafeArea(.top)

                        HStack {
                            Text("Hello, \(displayName)")
                                .font(.title)
                                .fontWeight(.bold)
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
                                .shadow(radius: 2)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 40)
                        .padding(.bottom, 10)
                    }
                    .frame(height: 120)
                    .padding(.bottom, 15)

                    // Search Bar
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.pink)
                            TextField("Search sets or folders...", text: $searchText)
                                .foregroundColor(.pink)
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.pink.opacity(0.4), lineWidth: 1))
                        .shadow(color: Color.pink.opacity(0.2), radius: 2, x: 0, y: 2)
                    }
                    .padding(.horizontal)

                    // Firebase Sets Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("All Sets (Cloud)")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(.leading)
                            .padding(.top, 10)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                if setViewModel.sets.isEmpty {
                                    Text("No sets yet.")
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding()
                                        .background(Color.pink.opacity(0.4))
                                        .cornerRadius(10)
                                } else {
                                    ForEach(setViewModel.sets.filter {
                                        searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText)
                                    }) { set in
                                        VStack(alignment: .leading) {
                                            Text(set.title)
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Text("\(set.terms.count) terms")
                                                .font(.subheadline)
                                                .foregroundColor(.white.opacity(0.7))
                                            Text("goawayplease_")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.6))
                                        }
                                        .padding()
                                        .background(Color.pink.opacity(0.8))
                                        .cornerRadius(16)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .frame(height: 240)
                    .background(Color.pink.opacity(0.2))
                    .cornerRadius(20)

                    // Local Sets Section (Unchanged)
                    contentSection(title: "All Sets (Local)", items: filteredSets.map { $0.deletingPathExtension().lastPathComponent })

                    // Folders Section (Unchanged)
                    contentSection(title: "Folders", items: filteredFolders.map { $0.lastPathComponent })

                    Spacer()

                    // Add Button
                    HStack {
                        Spacer()
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
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    func contentSection(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2)
                .foregroundColor(.white)
                .padding(.leading)
                .padding(.top, 10)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    if items.isEmpty {
                        Text("No \(title.lowercased()) yet.")
                            .foregroundColor(.white.opacity(0.7))
                            .padding()
                            .background(Color.pink.opacity(0.4))
                            .cornerRadius(10)
                    } else {
                        ForEach(items, id: \.self) { name in
                            Text(name)
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
        .background(Color.pink.opacity(0.2))
        .cornerRadius(20)
    }

    var placeholderCircle: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 44, height: 44)
            .overlay(Text(String(displayName.prefix(1))).font(.headline).foregroundColor(.pink))
    }

    var filteredSets: [URL] {
        searchText.isEmpty ? sets : sets.filter { $0.lastPathComponent.localizedCaseInsensitiveContains(searchText) }
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

