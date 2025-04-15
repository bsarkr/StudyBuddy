//
//  UserSetupView.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 4/12/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct UserSetupView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    let email: String
    let password: String

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var preferredName = ""
    @State private var errorMessage: String?
    @State private var goToVerification = false

    var body: some View {
        
        NavigationStack {
            ZStack {
                Color.pink.opacity(0.1).edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    HStack {
                        Button(action: {
                            cancelAndDelete()
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.pink)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    Text("Tell us about you")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.pink)

                    Group {
                        TextField("First Name*", text: $firstName)
                        TextField("Last Name*", text: $lastName)
                        TextField("Preferred Name (optional)", text: $preferredName)
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(10)
                    .shadow(radius: 1)
                    .padding(.horizontal)

                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                    }

                    Button(action: submitUserInfo) {
                        Text("Finish Setup")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.pink)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .shadow(radius: 3)
                    }

                    Spacer()
                }
                .padding(.top)
                .navigationBarBackButtonHidden(true)
            }
            .navigationDestination(isPresented: $goToVerification) {
                EmailVerificationView(email: email).environmentObject(authViewModel)
            }
        }
    }

    func submitUserInfo() {
        
        print("🧠 goToVerification: \(goToVerification)")
        
        
        guard !firstName.isEmpty, !lastName.isEmpty else {
            errorMessage = "Please enter your first and last name."
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }

            guard let user = result?.user else {
                errorMessage = "User creation failed."
                return
            }

            user.sendEmailVerification { error in
                if let error = error {
                    errorMessage = "Failed to send verification email: \(error.localizedDescription)"
                    return
                }

                let userData: [String: Any] = [
                    "firstName": firstName,
                    "lastName": lastName,
                    "preferredName": preferredName,
                    "email": email
                ]

                Firestore.firestore().collection("users").document(user.uid).setData(userData) { error in
                    if let error = error {
                        errorMessage = "Error saving user data: \(error.localizedDescription)"
                        return
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        print("⏩ navigating now!")
                        goToVerification = true
                    }
                }
            }
        }
    }

    func cancelAndDelete() {
        guard let user = Auth.auth().currentUser else {
            dismiss()
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(user.uid).delete { _ in
            user.delete { _ in
                try? Auth.auth().signOut()
                authViewModel.isLoggedIn = false
                authViewModel.hasCompletedSetup = false
                authViewModel.isEmailVerified = false
                dismiss()
            }
        }
    }
}
