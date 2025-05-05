//
//  Library.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/4/25.

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

    var body: some View {
        ZStack {
            Color.clear // Allows background tap gesture to dismiss keyboard

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
                    Text("Folders").tag("folders") // Placeholder
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.pink)
                    TextField("Search sets...", text: $searchText)
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
                        } else {
                            Text("Folders view is not yet implemented.")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
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
        }
    }

    func groupByMonth(_ sets: [StudySet]) -> [(key: String, value: [StudySet])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        var grouped = [String: [StudySet]]()

        for set in sets {
            let date = set.timestamp.dateValue()
            let key = formatter.string(from: date)
            grouped[key, default: []].append(set)
        }

        // Sort months descending by actual date, not just string key
        let sortedKeys = grouped.keys.sorted {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            guard let date1 = formatter.date(from: $0), let date2 = formatter.date(from: $1) else { return false }
            return date1 > date2
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
                if let error = error {
                    print("Error fetching sets: \(error)")
                    return
                }

                if let documents = snapshot?.documents {
                    let fetchedSets = documents.compactMap { doc -> StudySet? in
                        return StudySet(id: doc.documentID, data: doc.data())
                    }
                    self.allSets = fetchedSets
                    self.groupedSets = groupByMonth(fetchedSets)
                }
            }
    }
}
