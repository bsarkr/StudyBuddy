//
//  ForgotPasswordView.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/6/25.
//

import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var message: String?
    @State private var errorMessage: String?
    @State private var emailSent = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                Color.pink.opacity(0.15).ignoresSafeArea()

                VStack(spacing: 30) {
                    Spacer().frame(height: 60)

                    Text("Reset Your Password")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.pink)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    VStack(spacing: 20) {
                        TextField("Enter your email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)

                        if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                        }

                        if let message = message {
                            Text(message)
                                .foregroundColor(.green)
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 30)

                    Button(action: sendResetEmail) {
                        Text("Submit")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.pink)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 30)
                    .shadow(radius: 5)

                    Spacer()
                }

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
            }
            .navigationBarBackButtonHidden(true)
        }
        .onChange(of: emailSent) { sent in
            if sent {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    dismiss()
                }
            }
        }
    }

    func sendResetEmail() {
        errorMessage = nil
        message = nil

        guard !email.isEmpty else {
            errorMessage = "Email field cannot be empty."
            return
        }

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                self.message = "A reset link was sent to your email."
                self.emailSent = true
            }
        }
    }
}

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
    }
}
