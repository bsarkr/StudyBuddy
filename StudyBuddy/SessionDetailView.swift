//
//  SessionDetailView.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/8/25.
//

import SwiftUI
import FirebaseFirestore

struct SessionDetailView: View {
    var session: StudySession

    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = SetViewModel()
    @State private var allSets: [StudySet] = []
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 1.0, green: 0.93, blue: 0.95).ignoresSafeArea()

                VStack(spacing: 16) {
                    // Session ID
                    VStack(spacing: 4) {
                        Text("Session ID:")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text(session.sessionCode)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.pink)
                    }
                    .padding(.top)

                    if allSets.isEmpty {
                        Spacer()
                        Text("No sets in this session yet.")
                            .foregroundColor(.gray)
                            .padding(.top, 40)
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 20) {
                                ForEach(allSets, id: \.id) { set in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(set.title)
                                            .font(.headline)
                                            .foregroundColor(.pink)

                                        Text("Added by: \(set.creatorUsername)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)

                                        Divider()

                                        ForEach(set.terms.prefix(3), id: \.term) { card in
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(card.term)
                                                    .font(.subheadline)
                                                    .bold()
                                                Text(card.definition)
                                                    .font(.subheadline)
                                                    .foregroundColor(.black.opacity(0.75))
                                            }
                                        }

                                        NavigationLink(destination: SetDetailView(set: set)) {
                                            Text("View Full Set")
                                                .font(.footnote)
                                                .foregroundColor(.blue)
                                                .padding(.top, 6)
                                        }
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(14)
                                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 80)
                        }
                    }
                }

                // Back Button
                VStack {
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.pink)
                                .padding(10)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        }
                        .padding(.leading, 16)
                        .padding(.top, 16)
                        Spacer()
                    }
                    Spacer()
                }

                // Add Sets Button
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            showAddSheet = true
                        }) {
                            Image(systemName: "plus.circle")
                                .font(.title2)
                                .foregroundColor(.pink)
                                .padding(10)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        }
                        .padding(.top, 16)
                        .padding(.trailing, 16)
                    }
                    Spacer()
                }
            }
            .navigationBarBackButtonHidden(true)
        }
        .onAppear {
            fetchSessionSets()
        }
        .sheet(isPresented: $showAddSheet) {
            AddSetsToSessionSheet(session: session)
        }
    }

    func fetchSessionSets() {
        guard let sessionID = session.id else { return }

        let db = Firestore.firestore()
        db.collection("sessions").document(sessionID).getDocument { snapshot, error in
            guard let data = try? snapshot?.data(as: StudySession.self) else { return }

            let setIDs = Array(data.setIDs.keys)

            viewModel.fetchSetsByIDs(setIDs) { sets in
                self.allSets = sets.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
            }
        }
    }
}
