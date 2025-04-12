//
//  EmailVerificationView.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 4/13/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EmailVerificationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var isVerified = false
    @State private var timer: Timer?
    @State private var error: String?

    var body: some View {
        ZStack {
            Color.pink.opacity(0.1).edgesIgnoringSafeArea(.all)

            VStack(spacing: 24) {
                HStack {
                    Button(action: cancelAndDeleteAccount) {
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
                .navigationBarBackButtonHidden(true)
                .fullScreenCover(isPresented: $isVerified) {
                    Homepage().environmentObject(authViewModel)
                }

                Spacer()

                Text("📧 Check Your Email")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.pink)

                Text("We’ve sent a verification link to your email. Please verify to continue.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding()

                Button("Resend Email") {
                    Auth.auth().currentUser?.sendEmailVerification()
                }
                .padding()
                .background(Color.pink)
                .foregroundColor(.white)
                .cornerRadius(10)

                Spacer()
            }
            .padding()
        }
        .onAppear(perform: startChecking)
        .onDisappear {
            timer?.invalidate()
        }
        .fullScreenCover(isPresented: $isVerified) {
            Homepage().environmentObject(authViewModel)
        }
    }

    func startChecking() {
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            Auth.auth().currentUser?.reload { error in
                if let user = Auth.auth().currentUser, user.isEmailVerified {
                    timer?.invalidate()
                    isVerified = true
                }
            }
        }
    }

    func cancelAndDeleteAccount() {
        guard let user = Auth.auth().currentUser else { return }
        let uid = user.uid

        Firestore.firestore().collection("users").document(uid).delete()
        user.delete { _ in
            try? Auth.auth().signOut()
            authViewModel.isLoggedIn = false
            authViewModel.hasCompletedSetup = false
            dismiss()
        }
    }
}
