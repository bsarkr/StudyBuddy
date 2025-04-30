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
            Homepage()
                .environmentObject(authViewModel)
                .preferredColorScheme(.light)
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
        NavigationStack {
            Group {
                if authViewModel.isLoggedIn {
                    if !authViewModel.hasCompletedSetup {
                        if authViewModel.isCreatingAccount, let email = Auth.auth().currentUser?.email {
                            UserSetupView(email: email, password: "") //step 1
                        } else {
                            Homepage() // logged-in users skip setup
                        }
                    } else if !authViewModel.isEmailVerified {
                        if let email = Auth.auth().currentUser?.email {
                            EmailVerificationView(email: email) //step 2
                        } else {
                            Homepage()
                        }
                    } else {
                        Homepage() //step 3 or reload
                    }
                } else {
                    LoginView()
                }
            }
        }
    }
}

/*change view to this when done testing homepage

 WindowGroup {
    RootView()
        .environmentObject(authViewModel)
        .preferredColorScheme(.light)
}

OR
 
 WindowGroup {
     Homepage()
         .environmentObject(authViewModel)
         .preferredColorScheme(.light)
 }
 
*/
