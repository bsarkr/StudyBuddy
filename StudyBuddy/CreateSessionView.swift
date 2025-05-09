//
//  CreateSessionView.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/8/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CreateSessionView: View {
    @Environment(\.dismiss) var dismiss
    var sessionVM: SessionViewModel
    @StateObject var setViewModel = SetViewModel()
    
    @State private var sessionName: String = ""
    @State private var selectedSetIDs: Set<String> = []
    @State private var creating = false
    
    var onSessionCreated: (StudySession) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.95, green: 0.9, blue: 0.95).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Session name input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Session Name")
                            .font(.headline)
                            .foregroundColor(Color.pink)
                        TextField("Enter a session name", text: $sessionName)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.pink.opacity(0.4)))
                    }
                    .padding()
                    
                    // Scrollable set list
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
                    
                    // Fixed Create Session button
                    Button(action: createSession) {
                        if creating {
                            ProgressView()
                                .padding()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Create Session")
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
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
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
    
    
    func createSession() {
        guard let user = Auth.auth().currentUser,
              !sessionName.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        creating = true

        let mappedSetIDs: [String: String] = setViewModel.sets
            .filter { selectedSetIDs.contains($0.id) && ($0.creatorUsername ?? "").isEmpty == false }
            .reduce(into: [:]) { dict, set in
                if let username = set.creatorUsername {
                    dict[set.id] = username
                }
            }

        print("Selected Set IDs: \(selectedSetIDs)")
        print("Mapped Set IDs: \(mappedSetIDs)")
        
        sessionVM.createSession(name: sessionName, selectedSetIDs: mappedSetIDs) { newSession in
            creating = false
            if let newSession = newSession {
                onSessionCreated(newSession)
                dismiss()
            }
        }
    }
}
