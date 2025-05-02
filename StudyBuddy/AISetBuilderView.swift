//
//  AISetBuilderView.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/2/25.
//

import SwiftUI

struct AISetBuilderView: View {
    @Environment(\.dismiss) var dismiss

    @Binding var title: String
    @Binding var terms: [FlashcardTerm]
    @Binding var didSaveSet: Bool

    var setViewModel: SetViewModel

    @State private var prompt: String = ""
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        ZStack {
            Color.pink.opacity(0.15).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("AI Flashcard Builder")
                    .font(.title2)
                    .bold()
                    .padding(.top)

                TextField("Enter a topic, study guide, or question set...", text: $prompt, axis: .vertical)
                    .lineLimit(5...10)
                    .padding()
                    .background(Color.white.opacity(0.95))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.pink.opacity(0.4), lineWidth: 1)
                    )
                    .padding(.horizontal)

                if isLoading {
                    ProgressView("Generating...")
                        .padding(.horizontal)
                }

                if let error = error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                Button("Generate Flashcards") {
                    generate()
                }
                .disabled(prompt.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.pink)
                .foregroundColor(.white)
                .cornerRadius(15)
                .shadow(color: .pink.opacity(0.3), radius: 5, x: 0, y: 3)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.pink)
                }
            }
        }
    }

    func generate() {
        error = nil
        isLoading = true

        ChatGPTService.shared.generateFlashcardSet(from: prompt) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response):
                    self.title = response.title
                    self.terms = response.flashcards.map { FlashcardTerm(term: $0.term, definition: $0.definition) }
                    self.didSaveSet = true
                    dismiss()
                case .failure(let err):
                    self.error = err.localizedDescription
                }
            }
        }
    }
}
