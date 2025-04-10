import SwiftUI

struct Homepage: View {
    @State private var userName: String = "User"
    @State private var sets: [URL] = []
    @State private var folders: [URL] = []

    let libraryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("library")

    var body: some View {
        ZStack {
            Color.pink.opacity(0.15).edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // Top Pink Header
                ZStack(alignment: .bottomLeading) {
                    Color.pink
                    Text("Hello, \(userName)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.bottom, 30)
                        .padding(.leading)
                }
                .frame(height: 150)
                .edgesIgnoringSafeArea(.top)

                

                // Sets Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("All Sets")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(.top, 12)
                        .padding(.leading)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            if sets.isEmpty {
                                Text("No sets created yet.")
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding()
                                    .background(Color.pink.opacity(0.4))
                                    .cornerRadius(10)
                            } else {
                                ForEach(sets, id: \.self) { setURL in
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

               

                // Folders Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Folders")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(.top, 12)
                        .padding(.leading)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            if folders.isEmpty {
                                Text("No folders yet.")
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding()
                                    .background(Color.pink.opacity(0.4))
                                    .cornerRadius(10)
                            } else {
                                ForEach(folders, id: \.self) { folderURL in
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

                // Bottom Button
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
        }
        .onAppear {
            createLibraryDirectoryIfNeeded()
            loadFoldersAndSets()
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
}

struct Homepage_Previews: PreviewProvider {
    static var previews: some View {
        Homepage()
    }
}
