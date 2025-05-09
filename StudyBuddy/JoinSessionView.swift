//
//  JoinSessionView.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/8/25.
//

import SwiftUI

struct JoinSessionView: View {
    @Environment(\.dismiss) var dismiss
    var sessionVM: SessionViewModel

    @State private var sessionCode = ""
    @State private var errorMessage: String? = nil
    @State private var isJoining = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.95, green: 0.9, blue: 0.95).ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer().frame(height: 60)

                    Text("Join a Session")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.pink)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter Session Code")
                            .font(.headline)
                            .foregroundColor(.pink)

                        TextField("ABC123", text: $sessionCode)
                            .textInputAutocapitalization(.characters)
                            .disableAutocorrection(true)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.pink.opacity(0.4)))
                    }
                    .padding(.horizontal)

                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }

                    Button(action: joinSession) {
                        if isJoining {
                            ProgressView()
                                .padding()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Join Session")
                                .foregroundColor(.white)
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(Color.pink)
                    .cornerRadius(16)
                    .padding(.horizontal)

                    Spacer()
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
        }
    }

    func joinSession() {
        errorMessage = nil
        guard !sessionCode.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter a session code."
            return
        }

        isJoining = true
        sessionVM.joinSession(code: sessionCode.trimmingCharacters(in: .whitespacesAndNewlines)) { success in
            isJoining = false
            if success {
                dismiss()
            } else {
                errorMessage = "Session not found. Double-check your code!"
            }
        }
    }
}
