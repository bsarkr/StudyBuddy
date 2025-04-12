//
//  StudyBuddyApp.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar and Max Hazelton on 4/10/25.
//

import SwiftUI
import Firebase

@main
struct StudyBuddyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if authViewModel.isLoggedIn {
                if !authViewModel.hasCompletedSetup {
                    UserSetupView(email: "", password: "")
                } else if !authViewModel.isEmailVerified {
                    EmailVerificationView()
                } else {
                    Homepage()
                }
            } else {
                LoginView()
            }
        }
    }
}

