//
//  EditFolderView.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/6/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditFolderView: View {
    let folder: StudyFolder
    @EnvironmentObject var setViewModel: SetViewModel
    @Environment(\.dismiss) var dismiss

    @State private var selectedSetIDs: Set<String> = []
    @State private var isSaving = false

    var sortedSets: [StudySet] {
        setViewModel.sets.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.pink.opacity(0.1).ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer().frame(height: 60)

                Text("Edit Folder")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.pink)
                    .padding(.horizontal)

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(sortedSets) { set in
                            Button(action: {
                                toggleSelection(for: set.id)
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(set.title)
                                            .font(.headline)
                                            .foregroundColor(.pink)
                                        Text("\(set.terms.count) terms")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Image(systemName: selectedSetIDs.contains(set.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedSetIDs.contains(set.id) ? .pink : .gray)
                                        .font(.title3)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(14)
                                .shadow(color: .gray.opacity(0.1), radius: 3, x: 0, y: 2)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }

                Button(action: saveChanges) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.pink)
                            .cornerRadius(15)
                            .padding(.horizontal)
                    } else {
                        Text("Save Changes")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.pink)
                            .cornerRadius(15)
                            .shadow(color: .pink.opacity(0.3), radius: 5, x: 0, y: 3)
                            .padding(.horizontal)
                    }
                }

                Spacer()
            }

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
        .onAppear {
            selectedSetIDs = Set(folder.setIDs)
        }
        .navigationBarBackButtonHidden(true)
    }

    func toggleSelection(for id: String) {
        if selectedSetIDs.contains(id) {
            selectedSetIDs.remove(id)
        } else {
            selectedSetIDs.insert(id)
        }
    }

    func saveChanges() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isSaving = true

        Firestore.firestore()
            .collection("users")
            .document(userId)
            .collection("folders")
            .document(folder.id)
            .updateData([
                "setIDs": Array(selectedSetIDs),
                "timestamp": Timestamp(date: Date())
            ]) { error in
                isSaving = false
                if error == nil {
                    dismiss()
                }
                // Optional: handle errors visually
            }
    }
}
