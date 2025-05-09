//
//  GameSelectionView.swift
//  StudyBuddy
//
//  Created by Max Hazelton on 5/6/25.
//  Styled by Bilash Sarkar on 5/9/25
//

import SwiftUI

struct GameSelectionView: View {
    let set: StudySet
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                Color.pink.opacity(0.1).ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    Text("Choose a Game Mode")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.pink)

                    VStack(spacing: 20) {

                        NavigationLink(destination: FlashcardsView(set: set)) {
                            Text("Flashcards")
                        }
                        .gameButtonStyle()

                        NavigationLink(destination: MatchMeView(set: set)) {
                            Text("Match Me")
                        }
                        .gameButtonStyle()
                        
                        NavigationLink(destination: PracticeTestView(set: set)) {
                            Text("Practice Test")
                        }
                        .gameButtonStyle()
                    }
                    .padding(.horizontal)

                    Spacer()
                }

                // Custom Back Button
                Button(action: {
                    dismiss()
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
        }
        .navigationBarBackButtonHidden(true)
    }
}

private extension View {
    func gameButtonStyle() -> some View {
        self
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.pink)
            .foregroundColor(.white)
            .font(.headline)
            .cornerRadius(14)
            .shadow(color: Color.pink.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}
