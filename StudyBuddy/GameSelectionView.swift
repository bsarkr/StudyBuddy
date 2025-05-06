//
//  GameSelectionView.swift
//  StudyBuddy
//
//  Created by Max Hazelton on 5/6/25.
//

import SwiftUI

struct GameSelectionView: View {
    let set: StudySet

    var body: some View {
        VStack(spacing: 24) {
            Text("Choose a Game Mode")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)

            NavigationLink("Practice Test") {
                PracticeTestView(set: set)
            }
            .gameButtonStyle()

            NavigationLink("Flashcards") {
                Text("Flashcards View for \(set.title)") // Replace with actual view
            }
            .gameButtonStyle()

            NavigationLink("Match Me") {
                Text("Match Me Game View for \(set.title)") // Replace with actual view
            }
            .gameButtonStyle()

            Spacer()
        }
        .padding()
        .navigationTitle("Games")
    }
}

private extension View {
    func gameButtonStyle() -> some View {
        self
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.pink)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: Color.pink.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}
