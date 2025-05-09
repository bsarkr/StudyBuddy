//
//  PracticeTestView.swift
//  StudyBuddy
//
//  Created by Max Hazelton on 5/6/25.
//  Styling updated by Bilash Sarkar on 5/9/25
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
    @State private var shuffledTerms: [FlashcardTerm]

    init(set: StudySet) {
        self.set = set
        _shuffledTerms = State(initialValue: set.terms.shuffled())
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color.pink.opacity(0.1)
                    .edgesIgnoringSafeArea(.top)
                    .frame(height: 60)

                // Back button aligned to the left
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
                }

                // Centered title
                Text("Practice Test")
                    .font(.headline)
                    .foregroundColor(.black)
            }

            ZStack {
                Color.pink.opacity(0.1).ignoresSafeArea()

                VStack {
                    if showResult {
                        VStack(spacing: 24) {
                            Text("You got \(score) out of \(shuffledTerms.count) correct!")
                                .font(.title)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)

                            if !incorrectTerms.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Terms to Study:")
                                        .font(.headline)
                                        .foregroundColor(.pink)
                                        .padding(.horizontal)

                                    ScrollView {
                                        LazyVStack(spacing: 16) {
                                            ForEach(incorrectTerms, id: \.self) { term in
                                                if let definition = shuffledTerms.first(where: { $0.term == term })?.definition {
                                                    VStack(alignment: .leading, spacing: 6) {
                                                        Text(term)
                                                            .font(.subheadline)
                                                            .fontWeight(.semibold)
                                                            .foregroundColor(.black)

                                                        Text(definition)
                                                            .font(.body)
                                                            .foregroundColor(.gray)
                                                            .fixedSize(horizontal: false, vertical: true)
                                                    }
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .padding()
                                                    .background(Color.white)
                                                    .cornerRadius(12)
                                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                                    .padding(.horizontal)
                                                }
                                            }
                                        }
                                        .padding(.top, 4)
                                    }
                                    .frame(height: 400)
                                }
                            }

                            VStack(spacing: 16) {
                                Button(action: restartQuiz) {
                                    Text("Restart")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.white)
                                        .foregroundColor(.pink)
                                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.pink, lineWidth: 2))
                                        .cornerRadius(14)
                                }

                                Button(action: { dismiss() }) {
                                    Text("Quit Test")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.pink)
                                        .foregroundColor(.white)
                                        .cornerRadius(14)
                                        .shadow(color: Color.pink.opacity(0.3), radius: 4, x: 0, y: 3)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                    } else if shuffledTerms.indices.contains(currentIndex) {
                        let currentTerm = shuffledTerms[currentIndex]

                        GeometryReader { geo in
                            VStack {
                                Spacer(minLength: 20)

                                VStack(spacing: 24) {
                                    Text(currentTerm.term)
                                        .font(.system(size: 30, weight: .bold))
                                        .multilineTextAlignment(.center)
                                        .lineLimit(nil)
                                        .minimumScaleFactor(0.4)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .frame(maxWidth: .infinity)
                                        .padding(.horizontal)

                                    ScrollView {
                                        LazyVStack(spacing: 16) {
                                            ForEach(options, id: \.self) { option in
                                                Button(action: {
                                                    handleAnswer(selected: option)
                                                }) {
                                                    Text(option)
                                                        .font(.body)
                                                        .multilineTextAlignment(.leading)
                                                        .lineLimit(nil)
                                                        .fixedSize(horizontal: false, vertical: true)
                                                        .padding()
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                        .background(backgroundColor(for: option))
                                                        .foregroundColor(.white)
                                                        .cornerRadius(12)
                                                }
                                                .disabled(selectedDefinition != nil)
                                                .opacity(animateCard ? 1 : 0)
                                                .offset(x: animateCard ? 0 : 30)
                                                .animation(.easeOut(duration: 0.4), value: animateCard)
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                    .frame(height: geo.size.height * 0.6)
                                }
                                .frame(maxHeight: geo.size.height * 0.85)

                                Spacer(minLength: 20)
                            }
                            .frame(width: geo.size.width, height: geo.size.height)
                            .onAppear {
                                generateOptions()
                                animateCard = true
                            }
                        }
                    } else {
                        Spacer()
                        ProgressView("Loading Practice Test...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .pink))
                            .font(.headline)
                        Spacer()
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }

    private func restartQuiz() {
        shuffledTerms = set.terms.shuffled()
        currentIndex = 0
        score = 0
        showResult = false
        selectedDefinition = nil
        incorrectTerms.removeAll()
        animateCard = true
        generateOptions()
    }

    private func handleAnswer(selected: String) {
        selectedDefinition = selected

        let correctDefinition = shuffledTerms[currentIndex].definition

        if selected == correctDefinition {
            score += 1
        } else {
            incorrectTerms.append(shuffledTerms[currentIndex].term)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            advanceQuestion()
        }
    }

    private func advanceQuestion() {
        selectedDefinition = nil
        currentIndex += 1
        animateCard = false

        if currentIndex >= shuffledTerms.count {
            showResult = true
        } else {
            generateOptions()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateCard = true
            }
        }
    }

    private func generateOptions() {
        guard shuffledTerms.indices.contains(currentIndex) else { return }

        let correctDefinition = shuffledTerms[currentIndex].definition

        let incorrectDefinitions = shuffledTerms
            .filter { $0.definition != correctDefinition }
            .map { $0.definition }
            .shuffled()

        let limitedIncorrect = Array(incorrectDefinitions.prefix(3))
        options = ([correctDefinition] + limitedIncorrect).shuffled()
    }

    private func backgroundColor(for option: String) -> Color {
        guard let selected = selectedDefinition else { return Color.pink }

        let correct = shuffledTerms[currentIndex].definition

        if option == correct {
            return .green
        } else if option == selected {
            return .red
        } else {
            return .pink.opacity(0.5)
        }
    }
}
