//
//  FlashcardsView.swift
//  StudyBuddy
//
//  Created by Max Hazelton on 5/8/25.
//

import SwiftUI

struct FlashcardsView: View {
    let set: StudySet

    @State private var remainingCards: [FlashcardTerm] = []
    @State private var currentCard: FlashcardTerm?
    @State private var isFlipped = false
    @State private var knownCards: [FlashcardTerm] = []
    @State private var unknownCards: [FlashcardTerm] = []
    @State private var showResults = false

    var body: some View {
        ZStack {
            Color.pink.opacity(0.1).ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Text("✅ \(knownCards.count)")
                        .font(.subheadline)
                        .foregroundColor(.green)
                    Spacer()
                    Text("❌ \(unknownCards.count)")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                .padding(.horizontal)

                if showResults {
                    resultsView
                } else {
                    if let card = currentCard {
                        FlipCardView(isFlipped: $isFlipped, front: card.term, back: card.definition)
                            .frame(height: 250)
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

                        Spacer()
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Flashcards")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            startGame()
        }
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
            .background(Color.pink)
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(radius: 2)
    }
}
