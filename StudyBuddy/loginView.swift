//
//  loginView.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 4/11/25.
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var goToSetup = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pink.opacity(0.15).edgesIgnoringSafeArea(.all)

                VStack(spacing: 30) {
                    Spacer()

                    Text("StudyBuddy")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.pink)

                    VStack(spacing: 20) {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)

                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)

                        if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 30)

                    Button(action: {
                        goToSetup = true
                    }) {
                        Text("Create Account")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.pink)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 30)
                    .shadow(radius: 5)

                    Button(action: login) {
                        Text("Already have an account? Log In")
                            .font(.footnote)
                            .foregroundColor(.pink)
                    }

                    Spacer()
                }
                .navigationDestination(isPresented: $goToSetup) {
                    UserSetupView(email: email, password: password)
                        .environmentObject(authViewModel)
                }
            }
        }
    }

    func login() {
        errorMessage = nil

        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else if let user = result?.user {
                user.reload { _ in
                    if user.isEmailVerified {
                        authViewModel.isLoggedIn = true
                        authViewModel.hasCompletedSetup = true
                    } else {
                        errorMessage = "Please verify your email to log in."
                        try? Auth.auth().signOut()
                    }
                }
            }
        }
    }
}
