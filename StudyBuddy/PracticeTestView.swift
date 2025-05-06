//
//  PracticeTestView.swift
//  StudyBuddy
//
//  Created by Max Hazelton on 5/6/25.
//

import SwiftUI

struct PracticeTestView: View {
    let set: StudySet

    @Environment(\.dismiss) var dismiss

    @State private var currentIndex = 0
    @State private var score = 0
    @State private var showResult = false
    @State private var selectedDefinition: String? = nil
    @State private var incorrectTerms: [String] = []
    @State private var options: [String] = []
    @State private var animateCard = false

    var body: some View {
        ZStack {
            Color.pink.opacity(0.1).ignoresSafeArea()

            if showResult {
                VStack(spacing: 24) {
                    Text("You got \(score) out of \(set.terms.count) correct!")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    if !incorrectTerms.isEmpty {
                        Text("Terms to Study:")
                            .font(.headline)

                        ForEach(incorrectTerms, id: \.self) { term in
                            Text(term)
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    Button(action: {
                        dismiss()
                    }) {
                        Text("Continue")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.pink)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .shadow(color: Color.pink.opacity(0.3), radius: 4, x: 0, y: 3)
                    }
                    .padding(.top, 24)

                    Spacer()
                }
                .padding()
            } else {
                let currentTerm = set.terms[currentIndex]
                VStack(spacing: 24) {
                    Text(currentTerm.term)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding()

                    ForEach(options, id: \.self) { option in
                        Button(action: {
                            handleAnswer(selected: option)
                        }) {
                            Text(option)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(backgroundColor(for: option))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .disabled(selectedDefinition != nil)
                        .opacity(animateCard ? 1 : 0)
                        .offset(x: animateCard ? 0 : 30)
                        .animation(.easeOut(duration: 0.4), value: animateCard)
                    }

                    Spacer()
                }
                .padding()
                .onAppear {
                    generateOptions()
                    animateCard = true
                }
            }
        }
        .navigationTitle("Practice Test")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func handleAnswer(selected: String) {
        selectedDefinition = selected

        let correctDefinition = set.terms[currentIndex].definition

        if selected == correctDefinition {
            score += 1
        } else {
            incorrectTerms.append(set.terms[currentIndex].term)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            advanceQuestion()
        }
    }

    private func advanceQuestion() {
        selectedDefinition = nil
        currentIndex += 1
        animateCard = false

        if currentIndex >= set.terms.count {
            showResult = true
        } else {
            generateOptions()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateCard = true
            }
        }
    }

    private func generateOptions() {
        let correctDefinition = set.terms[currentIndex].definition
        
        let incorrectDefinitions = set.terms
            .filter { $0.definition != correctDefinition }
            .map { $0.definition }
            .shuffled()

        let limitedIncorrect = Array(incorrectDefinitions.prefix(3))
        options = ([correctDefinition] + limitedIncorrect).shuffled()
    }


    private func backgroundColor(for option: String) -> Color {
        guard let selected = selectedDefinition else { return Color.pink }

        let correct = set.terms[currentIndex].definition

        if option == correct {
            return .green
        } else if option == selected {
            return .red
        } else {
            return .pink.opacity(0.5)
        }
    }
}
