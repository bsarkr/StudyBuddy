//
//  SessionsTabView.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/8/25.
//

import SwiftUI

struct SessionsTabView: View {
    @StateObject private var sessionVM = SessionViewModel()
    @State private var searchText = ""
    @State private var showSheet = false

    @State private var navigateToSession: StudySession? = nil
    @State private var showCreateSheet = false
    @State private var showJoinSheet = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Search sessions", text: $searchText)
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(10)

                Button(action: {
                    showSheet = true
                }) {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                        .foregroundColor(.pink)
                }
            }
            .padding()

            ScrollView {
                ForEach(sessionVM.sessions.filter {
                    $0.name.lowercased().contains(searchText.lowercased()) || searchText.isEmpty
                }) { session in
                    NavigationLink(destination: SessionDetailView(session: session)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(session.name)
                                    .font(.headline)
                                Text("Code: \(session.sessionCode)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onAppear {
            sessionVM.fetchSessions()
        }
        .sheet(isPresented: $showSheet) {
            SessionOptionsSheet(
                sessionVM: sessionVM,
                onSessionCreated: { newSession in
                    navigateToSession = newSession
                },
                isVisible: $showSheet,
                onTapCreate: { showCreateSheet = true },
                onTapJoin: { showJoinSheet = true }
            )
            .presentationDetents([.fraction(0.25)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateSessionView(
                sessionVM: sessionVM,
                onSessionCreated: { newSession in
                    navigateToSession = newSession
                }
            )
        }
        .sheet(isPresented: $showJoinSheet) {
            JoinSessionView(sessionVM: sessionVM)
        }
        .navigationDestination(item: $navigateToSession) { session in
            SessionDetailView(session: session)
        }
    }
}
