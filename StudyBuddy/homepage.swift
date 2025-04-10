import SwiftUI

struct Homepage: View {
    @State private var userName: String = "User"
    @State private var sets: [URL] = []
    @State private var folders: [URL] = []

    let libraryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("library")

    var body: some View {
        VStack(alignment: .leading) {
            Text("Hello, \(userName)")
                .font(.largeTitle)
                .padding(.top)

            Text("All Sets")
                .font(.headline)
                .padding(.leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(sets, id: \.self) { setURL in
                        Text(setURL.deletingPathExtension().lastPathComponent)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }

            Text("Folders")
                .font(.headline)
                .padding([.leading, .top])

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(folders, id: \.self) { folderURL in
                        Text(folderURL.lastPathComponent)
                            .padding()
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }

            Spacer()

            HStack {
                Spacer()
                Button(action: {
                    // Add new set action
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.pink)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(.bottom)
            }
        }
        .padding(.horizontal)
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

