//
//  MatchMeView.swift
//  StudyBuddy
//
//  Created by Max Hazelton on 5/6/25.
//

import SwiftUI

struct MatchMeView: View {
    let set: StudySet

    @State private var allTerms: [FlashcardTerm] = []
    @State private var usedTermIDs: Set<String> = []
    @State private var currentBatch: [FlashcardTerm] = []
    @State private var shuffledPairs: [Tile] = []
    @State private var selectedIndices: [Int] = []
    @State private var matchedIndices: Set<Int> = []
    @State private var showMismatch = false
    @State private var timerCount = 0
    @State private var gameComplete = false

    @Environment(\.dismiss) var dismiss
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            Color.pink.opacity(0.1).ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Match Me")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                Text("Time: \(timerCount) seconds")
                    .font(.headline)

                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4), spacing: 16) {
                    ForEach(shuffledPairs.indices, id: \.self) { index in
                        let tile = shuffledPairs[index]
                        TileView(
                            text: tile.text,
                            isMatched: matchedIndices.contains(index),
                            isSelected: selectedIndices.contains(index),
                            showMismatch: showMismatch && selectedIndices.contains(index)
                        )
                        .onTapGesture {
                            handleTap(index: index)
                        }
                        .disabled(matchedIndices.contains(index) || selectedIndices.contains(index))
                    }
                }
                .padding()

                if gameComplete {
                    Text("🎉 You matched all terms!")
                        .font(.headline)
                        .padding(.top, 10)

                    Button("Back to Set") {
                        dismiss()
                    }
                    .padding()
                    .background(Color.pink)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                Spacer()
            }
        }
        .onAppear {
            setupGame()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func setupGame() {
        timerCount = 0
        matchedIndices = []
        selectedIndices = []
        gameComplete = false

        allTerms = set.terms.shuffled()
        usedTermIDs = []
        loadNextBatch()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timerCount += 1
        }
    }

    private func loadNextBatch() {
        // Get unused terms
        let remaining = allTerms.filter { !usedTermIDs.contains($0.term) }
        let batch = Array(remaining.prefix(12))

        if batch.isEmpty {
            gameComplete = true
            return
        }

        currentBatch = batch
        usedTermIDs.formUnion(batch.map { $0.term })

        // Create tiles
        var tiles: [Tile] = []
        for card in batch {
            tiles.append(Tile(text: card.term, matchID: card.term))
            tiles.append(Tile(text: card.definition, matchID: card.term))
        }

        shuffledPairs = tiles.shuffled()
        matchedIndices = []
        selectedIndices = []
    }

    private func handleTap(index: Int) {
        selectedIndices.append(index)

        if selectedIndices.count == 2 {
            let first = shuffledPairs[selectedIndices[0]]
            let second = shuffledPairs[selectedIndices[1]]

            if first.matchID == second.matchID {
                matchedIndices.formUnion(selectedIndices)
                selectedIndices = []

                if matchedIndices.count == shuffledPairs.count {
                    // Delay slightly to show matched state before loading next batch
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        loadNextBatch()
                    }
                }
            } else {
                showMismatch = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    selectedIndices = []
                    showMismatch = false
                }
            }
        }
    }
}

// MARK: - Tile + TileView

struct Tile: Identifiable {
    let id = UUID()
    let text: String
    let matchID: String
}

struct TileView: View {
    let text: String
    let isMatched: Bool
    let isSelected: Bool
    let showMismatch: Bool

    var body: some View {
        Text(text)
            .font(.body)
            .lineLimit(4)
            .minimumScaleFactor(0.5)
            .multilineTextAlignment(.center)
            .truncationMode(.tail)
            .allowsTightening(true)
            .padding(6)
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(backgroundColor)
            .cornerRadius(12)
            .foregroundColor(.black)
            .animation(.easeInOut(duration: 0.3), value: backgroundColor)
    }

    var backgroundColor: Color {
        if isMatched {
            return Color.green.opacity(0.3)
        } else if showMismatch {
            return Color.red.opacity(0.5)
        } else if isSelected {
            return Color.pink.opacity(0.5)
        } else {
            return Color.white
        }
    }
}
