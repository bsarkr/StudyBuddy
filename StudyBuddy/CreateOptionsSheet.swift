//
//  CreateOptionsSheet.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/5/25.
//

import SwiftUI

struct CreateOptionsSheet: View {
    var onCreateSet: () -> Void
    var onCreateFolder: () -> Void

    var body: some View {
        ZStack {
            Color(red: 1.0, green: 0.85, blue: 0.9) 

            VStack(spacing: 20) {
                Capsule()
                    .frame(width: 40, height: 5)
                    .foregroundColor(.gray.opacity(0.3))
                    .padding(.top, 10)

                Button(action: onCreateSet) {
                    HStack {
                        Image(systemName: "plus.square")
                        Text("Create Set")
                    }
                    .font(.headline)
                    .foregroundColor(.pink)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(14)
                    .shadow(color: Color.pink.opacity(0.2), radius: 3, x: 0, y: 2)
                }

                Button(action: onCreateFolder) {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                        Text("Create Folder")
                    }
                    .font(.headline)
                    .foregroundColor(.purple)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(14)
                    .shadow(color: Color.purple.opacity(0.2), radius: 3, x: 0, y: 2)
                }

                Spacer()
            }
            .padding()
        }
        .ignoresSafeArea()
    }
}
