//
//  AddSetsToSessionSheet.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/8/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AddSetsToSessionSheet: View {
    @Environment(\.dismiss) var dismiss
    let session: StudySession

    @StateObject private var setViewModel = SetViewModel()
    @State private var selectedSetIDs: Set<String> = []
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.95, green: 0.9, blue: 0.95).ignoresSafeArea()

                VStack(spacing: 0) {
                    Text("Add Sets to Session")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.pink)
                        .padding(.top)
                        .padding(.bottom, 8)

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
                                            .foregroundColor(.pink)
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

                    Button(action: addSetsToSession) {
                        if isSubmitting {
                            ProgressView()
                                .padding()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Add Sets")
                                .foregroundColor(.white)
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(Color.pink)
                    .cornerRadius(16)
                    .padding([.horizontal, .bottom])
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.pink)
                }
            }
            .onAppear {
                if let userId = Auth.auth().currentUser?.uid {
                    setViewModel.fetchSets(for: userId)
                }
            }
        }
    }

    func addSetsToSession() {
        guard let user = Auth.auth().currentUser else { return }

        isSubmitting = true

        let newEntries: [String: String] = setViewModel.sets
            .filter { selectedSetIDs.contains($0.id) }
            .reduce(into: [String: String]()) { dict, set in
                dict[set.id] = set.creatorUsername
            }

        let db = Firestore.firestore()
        let ref = db.collection("sessions").document(session.id ?? "")

        // Fetch current setIDs dictionary, merge in new values
        ref.getDocument { document, error in
            guard let document = document, document.exists else {
                isSubmitting = false
                return
            }

            var currentSetIDs = document.data()?["setIDs"] as? [String: String] ?? [:]
            for (key, value) in newEntries {
                currentSetIDs[key] = value
            }

            ref.updateData(["setIDs": currentSetIDs]) { err in
                isSubmitting = false
                if err == nil {
                    dismiss()
                }
            }
        }
    }
}
