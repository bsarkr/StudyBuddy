//
//  UserAccountView.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 4/12/25.
//

import SwiftUI

struct UserAccountView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 20) {
            // Top header
            HStack {
                Text("Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.pink)
                Spacer()
            }
            .padding()
            .padding(.top, 40)

            // Placeholder for future settings
            VStack(spacing: 12) {
                Text("Settings")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(10)
                    .shadow(radius: 1)
            }
            .padding(.horizontal)

            Spacer()

            // Log out button
            Button(action: {
                withAnimation {
                    authViewModel.signOut()
                    presentationMode.wrappedValue.dismiss()
                }
            }) {
                Text("Log Out")
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(12)
                    .shadow(radius: 3)
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        //Text("Back")
                    }
                    .font(.headline)
                    .foregroundColor(.pink)
                    .padding(8)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(10)
                    .shadow(radius: 1)
                    .padding(.top, 60)
                }
            }
        }
        .background(Color.pink.opacity(0.1).edgesIgnoringSafeArea(.all))
    }
}

struct UserAccountView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            UserAccountView().environmentObject(AuthViewModel())
        }
    }
}
