//
//  CreateFolderView.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/5/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CreateFolderView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var setViewModel: SetViewModel

    @State private var folderName: String = ""
    @State private var selectedSetIDs: Set<String> = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.88, green: 0.82, blue: 1.0)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Folder name input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Folder Name")
                            .font(.headline)
                            .foregroundColor(Color.purple)
                        TextField("Enter a folder name", text: $folderName)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.purple.opacity(0.4)))
                    }
                    .padding()

                    // Scrollable sets list
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(
                                setViewModel.sets.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() }),
                                id: \.id
                            ) { set in
                                Button(action: {
                                    if selectedSetIDs.contains(set.id) {
                                        selectedSetIDs.remove(set.id)
                                    } else {
                                        selectedSetIDs.insert(set.id)
                                    }
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(set.title)
                                                .font(.headline)
                                                .foregroundColor(.black)
                                            Text("\(set.terms.count) terms")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                        Image(systemName: selectedSetIDs.contains(set.id) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(.purple)
                                            .imageScale(.large)
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 2)
                                }
                            }
                        }
                        .padding()
                    }

                    // Fixed Create Folder button
                    Button(action: createFolder) {
                        Text("Create Folder")
                            .foregroundColor(.white)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(16)
                            .padding([.horizontal, .bottom])
                    }
                }
            }
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.purple)
                }
            }
        }
    }

    func createFolder() {
        guard let userID = Auth.auth().currentUser?.uid,
              !folderName.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let folderData: [String: Any] = [
            "name": folderName,
            "setIDs": Array(selectedSetIDs),
            "timestamp": Timestamp()
        ]

        Firestore.firestore()
            .collection("users")
            .document(userID)
            .collection("folders")
            .addDocument(data: folderData) { error in
                if error == nil {
                    dismiss()
                }
            }
    }
}
