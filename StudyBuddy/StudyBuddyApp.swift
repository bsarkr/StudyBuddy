//
//  StudyBuddyApp.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar and Max Hazelton on 4/10/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseAppCheck

@main
struct StudyBuddyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .preferredColorScheme(.light)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        //Enables App Check Debug Provider
                #if DEBUG
                let providerFactory = AppCheckDebugProviderFactory()
                AppCheck.setAppCheckProviderFactory(providerFactory)
                #endif
        
        
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
                    EmailVerificationView(email: Auth.auth().currentUser?.email ?? "")
                } else {
                    Homepage()
                }
            } else {
                LoginView()
            }
        }
    }
}

