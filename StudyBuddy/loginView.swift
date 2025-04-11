//
//  loginView.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 4/11/25.
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isCreatingAccount = false
    @State private var isAuthenticated = false
    @State private var errorMessage: String?

    var body: some View {
        if isAuthenticated {
            Homepage()
        } else {
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
                        }
                    }
                    .padding(.horizontal, 30)

                    Button(action: authenticateUser) {
                        Text(isCreatingAccount ? "Create Account" : "Login")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.pink)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 30)
                    .shadow(radius: 5)

                    Button(action: {
                        isCreatingAccount.toggle()
                        errorMessage = nil
                    }) {
                        Text(isCreatingAccount ? "Already have an account? Login" : "Don't have an account? Sign Up")
                            .font(.footnote)
                            .foregroundColor(.pink)
                    }

                    Spacer()
                }
            }
        }
    }

    func authenticateUser() {
        errorMessage = nil
        if isCreatingAccount {
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error {
                    errorMessage = error.localizedDescription
                } else {
                    isAuthenticated = true
                }
            }
        } else {
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error = error {
                    errorMessage = error.localizedDescription
                } else {
                    isAuthenticated = true
                }
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
