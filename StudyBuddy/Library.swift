//
//  Library.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/4/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct LibraryView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var setViewModel = SetViewModel()

    @State private var selectedTab = "sets"
    @State private var searchText = ""
    @State private var allSets: [StudySet] = []
    @State private var groupedSets: [(key: String, value: [StudySet])] = []

    @State private var allFolders: [StudyFolder] = []
    @State private var groupedFolders: [(key: String, value: [StudyFolder])] = []

    @State private var refreshTrigger = false

    var body: some View {
        NavigationStack {
            ZStack {
                (selectedTab == "folders" ? Color(red: 0.93, green: 0.9, blue: 1.0) : Color.clear)
                        .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    ZStack(alignment: .bottomLeading) {
                        Color.pink.ignoresSafeArea(edges: .top)
                        Text("Library")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.white)
                            .padding(.leading)
                            .padding(.bottom, 10)
                    }
                    .frame(height: 70)

                    Picker("", selection: $selectedTab) {
                        Text("Sets").tag("sets")
                        Text("Folders").tag("folders")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()

                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.pink)
                        TextField("Search...", text: $searchText)
                            .foregroundColor(.pink)
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.pink.opacity(0.4), lineWidth: 1))
                    .padding(.horizontal)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            if selectedTab == "sets" {
                                let filtered = allSets.filter {
                                    searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText)
                                }
                                let grouped = groupByMonth(filtered)

                                if grouped.isEmpty {
                                    Text("No sets found.")
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                } else {
                                    ForEach(grouped, id: \.key) { section in
                                        VStack(alignment: .leading, spacing: 12) {
                                            Text(section.key)
                                                .font(.headline)
                                                .padding(.leading)

                                            ForEach(section.value.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() }), id: \.id) { set in
                                                NavigationLink(destination: SetDetailView(set: set).environmentObject(setViewModel)) {
                                                    VStack(alignment: .leading) {
                                                        Text(set.title)
                                                            .font(.headline)
                                                            .foregroundColor(.white)
                                                        Text("\(set.terms.count) terms")
                                                            .font(.subheadline)
                                                            .foregroundColor(.white.opacity(0.8))
                                                    }
                                                    .padding()
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .background(Color.pink.opacity(0.8))
                                                    .cornerRadius(10)
                                                    .padding(.horizontal)
                                                }
                                            }
                                        }
                                    }
                                }
                            } else {
                                let filtered = allFolders.filter {
                                    searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
                                }
                                let grouped = groupFoldersByMonth(filtered)

                                if grouped.isEmpty {
                                    Text("No folders found.")
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                } else {
                                    ForEach(grouped, id: \.key) { section in
                                        ZStack {
                                            VStack(alignment: .leading, spacing: 12) {
                                                Text(section.key)
                                                    .font(.headline)
                                                    .padding(.leading)

                                                ForEach(section.value.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() }), id: \.id) { folder in
                                                    folderCard(for: folder)
                                                }
                                            }
                                            .padding(.vertical, 12)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 50)
                    }
                }
                .onTapGesture {
                    UIApplication.shared.endEditing()
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onAppear {
                fetchSetsFromFirebase()
                fetchFoldersFromFirebase()
            }
        }
        .id(refreshTrigger)
    }

    @ViewBuilder
    func folderCard(for folder: StudyFolder) -> some View {
        let totalTerms = folder.setIDs.reduce(0) { count, setID in
            count + (setViewModel.sets.first { $0.id == setID }?.terms.count ?? 0)
        }

        let folderView = FolderDetailView(
            folder: folder,
            onDelete: {
                fetchFoldersFromFirebase()
                refreshTrigger.toggle()
            }
        ).environmentObject(setViewModel)

        NavigationLink(destination: folderView) {
            VStack(alignment: .leading) {
                Text(folder.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Text("\(totalTerms) terms")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.purple.opacity(0.7))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }

    func groupByMonth(_ sets: [StudySet]) -> [(key: String, value: [StudySet])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        var grouped = [String: [StudySet]]()
        for set in sets {
            let key = formatter.string(from: set.timestamp.dateValue())
            grouped[key, default: []].append(set)
        }

        let sortedKeys = grouped.keys.sorted {
            formatter.date(from: $0)! > formatter.date(from: $1)!
        }

        return sortedKeys.map { ($0, grouped[$0] ?? []) }
    }

    func groupFoldersByMonth(_ folders: [StudyFolder]) -> [(key: String, value: [StudyFolder])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        var grouped = [String: [StudyFolder]]()
        for folder in folders {
            let key = formatter.string(from: folder.timestamp.dateValue())
            grouped[key, default: []].append(folder)
        }

        let sortedKeys = grouped.keys.sorted {
            formatter.date(from: $0)! > formatter.date(from: $1)!
        }

        return sortedKeys.map { ($0, grouped[$0] ?? []) }
    }

    func fetchSetsFromFirebase() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("sets")
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents, error == nil else { return }
                let fetched = documents.compactMap { doc in
                    StudySet(id: doc.documentID, data: doc.data())
                }
                self.allSets = fetched
                self.groupedSets = groupByMonth(fetched)
                self.setViewModel.sets = fetched
            }
    }

    func fetchFoldersFromFirebase() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("folders")
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents, error == nil else { return }
                let fetched = documents.compactMap { doc in
                    StudyFolder(id: doc.documentID, data: doc.data())
                }
                self.allFolders = fetched
                self.groupedFolders = groupFoldersByMonth(fetched)
            }
    }
}
