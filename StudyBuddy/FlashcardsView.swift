//
//  FlashcardsView.swift
//  StudyBuddy
//
//  Created by Max Hazelton on 5/8/25.
//  Updated styling by Bilash Sarkar on 5/9/25
//

import SwiftUI

struct FlashcardsView: View {
    let set: StudySet

    @Environment(\.dismiss) var dismiss

    @State private var remainingCards: [FlashcardTerm] = []
    @State private var currentCard: FlashcardTerm?
    @State private var isFlipped = false
    @State private var knownCards: [FlashcardTerm] = []
    @State private var unknownCards: [FlashcardTerm] = []
    @State private var showResults = false

    var body: some View {
        ZStack {
            Color.pink.opacity(0.1).ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack {
                    Color.pink.opacity(0.1)
                        .frame(height: 60)
                        .ignoresSafeArea(edges: .top)

                    HStack {
                        Button(action: {
                            withAnimation { dismiss() }
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

                        Spacer()

                        if !showResults {
                            Button("Reset") {
                                startGame()
                            }
                            .fontWeight(.semibold)
                            .foregroundColor(.pink)
                            .padding(.trailing, 16)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 8)

                    Text("Flashcards")
                        .font(.headline)
                        .foregroundColor(.black)
                }

                Spacer()

                if showResults {
                    resultsView
                } else {
                    VStack(spacing: 20) {
                        // ✅ Score Row
                        HStack {
                            Text("✅ \(knownCards.count)")
                                .font(.subheadline)
                                .foregroundColor(.green)
                            Spacer()
                            Text("❌ \(unknownCards.count)")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                        .frame(width: 300)

                        if let card = currentCard {
                            VStack(spacing: 20) {
                                FlipCardView(isFlipped: $isFlipped, front: card.term, back: card.definition)
                                    .frame(width: 320, height: 220)
                                    .onTapGesture {
                                        withAnimation {
                                            isFlipped.toggle()
                                        }
                                    }

                                if isFlipped {
                                    HStack(spacing: 24) {
                                        Button("Know it") {
                                            knownCards.append(card)
                                            advanceCard()
                                        }
                                        .gameButtonStyle()

                                        Button("Don't know it") {
                                            unknownCards.append(card)
                                            advanceCard()
                                        }
                                        .gameButtonStyle()
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 50)
                }

                Spacer()
            }
            .onAppear { startGame() }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true)
    }

    private func startGame() {
        remainingCards = set.terms.shuffled()
        currentCard = remainingCards.popLast()
        knownCards = []
        unknownCards = []
        isFlipped = false
        showResults = false
    }

    private func advanceCard() {
        isFlipped = false
        if remainingCards.isEmpty {
            currentCard = nil
            showResults = true
        } else {
            currentCard = remainingCards.popLast()
        }
    }

    private var resultsView: some View {
        VStack(spacing: 20) {
            Text("You knew \(knownCards.count) out of \(knownCards.count + unknownCards.count) cards.")
                .font(.title2)
                .fontWeight(.semibold)

            let percentage = Double(knownCards.count) / Double(knownCards.count + unknownCards.count) * 100
            Text("Score: \(Int(percentage))%")
                .font(.headline)
                .foregroundColor(.pink)

            Button("Play Again") {
                startGame()
            }
            .gameButtonStyle()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if !knownCards.isEmpty {
                        Text("✅ Known Terms")
                            .font(.headline)
                        ForEach(knownCards, id: \.term) { card in
                            Text("- \(card.term)")
                        }
                    }

                    if !unknownCards.isEmpty {
                        Text("❌ Unknown Terms")
                            .font(.headline)
                            .padding(.top)

                        ForEach(unknownCards, id: \.term) { card in
                            Text("- \(card.term)")
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
    }
}

struct FlipCardView: View {
    @Binding var isFlipped: Bool
    let front: String
    let back: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(radius: 5)

            Group {
                if isFlipped {
                    Text(back)
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                } else {
                    Text(front)
                }
            }
            .padding()
            .font(.title2)
            .multilineTextAlignment(.center)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .rotation3DEffect(
            .degrees(isFlipped ? 180 : 0),
            axis: (x: 0, y: 1, z: 0)
        )
        .animation(.easeInOut(duration: 0.4), value: isFlipped)
    }
}

private extension View {
    func gameButtonStyle() -> some View {
        self
            .font(.headline)
            .padding()
            .frame(minWidth: 140)
            .background(Color.pink)
            .foregroundColor(.white)
            .cornerRadius(14)
            .shadow(color: Color.pink.opacity(0.3), radius: 4, x: 0, y: 3)
    }
}
