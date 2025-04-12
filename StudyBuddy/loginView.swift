//
//  LoginView.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 4/11/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var isCreatingAccount = false // 👈 defaults to false = login mode
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
                        Text(isCreatingAccount ? "Already have an account? Log In" : "Don't have an account? Sign Up")
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

    func authenticateUser() {
        errorMessage = nil

        if isCreatingAccount {
            // 👉 Skip Firebase account creation here, go to setup first
            goToSetup = true
        } else {
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                DispatchQueue.main.async {
                    if let error = error as NSError? {
                        switch AuthErrorCode(rawValue: error.code) {
                        case .userNotFound:
                            self.errorMessage = "No account found with that email."
                        case .wrongPassword:
                            self.errorMessage = "Incorrect password. Please try again."
                        case .invalidEmail:
                            self.errorMessage = "Invalid email format."
                        case .userDisabled:
                            self.errorMessage = "This account has been disabled."
                        default:
                            self.errorMessage = error.localizedDescription
                        }
                    } else if let user = result?.user {
                        authViewModel.isLoggedIn = true

                        let db = Firestore.firestore()
                        db.collection("users").document(user.uid).getDocument { snapshot, _ in
                            if let data = snapshot?.data() {
                                let setup = data["setupComplete"] as? Bool ?? false
                                authViewModel.hasCompletedSetup = setup
                            } else {
                                authViewModel.hasCompletedSetup = false
                            }
                        }
                    }
                }
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView().environmentObject(AuthViewModel())
    }
}
