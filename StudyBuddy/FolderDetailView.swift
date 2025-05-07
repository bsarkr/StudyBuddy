//
//  FolderDetailView.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/6/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FolderDetailView: View {
    let folder: StudyFolder
    var onDelete: (() -> Void)? = nil

    @EnvironmentObject var setViewModel: SetViewModel
    @Environment(\.dismiss) var dismiss

    @State private var showOptionsSheet = false
    @State private var isEditing = false

    var folderSets: [StudySet] {
        setViewModel.sets.filter { folder.setIDs.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                Color(red: 0.9, green: 0.85, blue: 1.0).ignoresSafeArea()

                VStack(spacing: 20) {
                    Spacer().frame(height: 60)

                    Text(folder.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.pink)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    if folderSets.isEmpty {
                        Text("No sets in this folder.")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(folderSets) { set in
                                    NavigationLink(destination: SetDetailView(set: set).environmentObject(setViewModel)) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(set.title)
                                                .font(.headline)
                                                .foregroundColor(.pink)

                                            Text("\(set.terms.count) terms")
                                                .font(.subheadline)
                                                .foregroundColor(.pink.opacity(0.6))
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.white)
                                        .cornerRadius(14)
                                        .shadow(color: .gray.opacity(0.1), radius: 3, x: 0, y: 2)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 100)
                        }
                    }

                    Spacer()
                }

                // Back Button
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

                // 3-dot Options Button
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            showOptionsSheet = true
                        }) {
                            Image(systemName: "ellipsis")
                                .font(.title2)
                                .foregroundColor(.pink)
                                .padding(10)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        }
                        .padding(.top, 16)
                        .padding(.trailing, 16)
                    }
                    Spacer()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showOptionsSheet) {
            FolderDetailsOptionsSheet(
                onEdit: {
                    isEditing = true
                    showOptionsSheet = false
                },
                onDelete: {
                    onDelete?() 
                    deleteFolder()
                    dismiss()
                }
            )
            .presentationDetents([.fraction(0.25)])
        }
        .sheet(isPresented: $isEditing) {
            EditFolderView(folder: folder)
                .environmentObject(setViewModel)
        }
    }

    func deleteFolder() {
        guard let userId = FirebaseAuth.Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("users")
            .document(userId)
            .collection("folders")
            .document(folder.id)
            .delete { error in
                if let error = error {
                    print("Error deleting folder: \(error.localizedDescription)")
                }
            }
    }
}
