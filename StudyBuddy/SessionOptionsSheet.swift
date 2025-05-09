//
//  SessionOptionsSheet.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/8/25.
//

import SwiftUI

struct SessionOptionsSheet: View {
    var sessionVM: SessionViewModel
    var onSessionCreated: (StudySession) -> Void
    @Binding var isVisible: Bool

    var onTapCreate: () -> Void
    var onTapJoin: () -> Void

    var body: some View {
        ZStack {
            // Light lavender background
            Color(red: 0.95, green: 0.88, blue: 1.0)

            VStack(spacing: 20) {
                // Top handle
                Capsule()
                    .frame(width: 40, height: 5)
                    .foregroundColor(.gray.opacity(0.3))
                    .padding(.top, 10)

                // Create Session button
                Button {
                    isVisible = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onTapCreate()
                    }
                } label: {
                    HStack {
                        Image(systemName: "plus.square")
                        Text("Create Session")
                    }
                    .font(.headline)
                    .foregroundColor(.pink)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(14)
                    .shadow(color: Color.pink.opacity(0.2), radius: 3, x: 0, y: 2)
                }

                // Join Session button
                Button {
                    isVisible = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onTapJoin()
                    }
                } label: {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Join Session")
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
