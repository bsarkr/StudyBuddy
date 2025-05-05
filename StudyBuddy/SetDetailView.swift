//
//  SetDetailView.swift
//  StudyBuddy
//
//  Logic created by Max Hazelton on 5/4/25.
//  Styled by Bilash on 5/5/25
//

import SwiftUI

struct SetDetailView: View {
    let set: StudySet

    @EnvironmentObject var viewModel: SetViewModel
    @Environment(\.dismiss) var dismiss

    @State private var showOptionsSheet = false
    @State private var isEditing = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                Color.pink.opacity(0.1).ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer().frame(height: 60)

                    Text(set.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.pink)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button(action: {
                        // Future: Navigate to game mode screen
                    }) {
                        Text("Learn")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.pink)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .shadow(color: Color.pink.opacity(0.3), radius: 4, x: 0, y: 3)
                    }
                    .padding(.horizontal)

                    // Scrollable Flashcards
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(set.terms, id: \.term) { card in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(card.term)
                                        .font(.headline)
                                        .foregroundColor(.pink)

                                    Text(card.definition)
                                        .font(.body)
                                        .foregroundColor(.black)
                                        .padding()
                                        .background(Color.white.opacity(0.9))
                                        .cornerRadius(12)

                                    Spacer(minLength: 10)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 80)
                    }
                }

                // Back Button
                Button(action: {
                    withAnimation {
                        dismiss()
                    }
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

                // Options Button
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            showOptionsSheet = true
                        }) {
                            Image(systemName: "ellipsis")
                                .font(.title2)
                                .foregroundColor(.pink)
                                .padding(10)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        }
                        .padding(.top, 16)
                        .padding(.trailing, 16)
                    }
                    Spacer()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showOptionsSheet) {
            SetDetailsOptionsSheet(
                onEdit: {
                    isEditing = true
                    showOptionsSheet = false
                },
                onDelete: {
                    viewModel.deleteSet(set)
                    dismiss()
                }
            )
            .presentationDetents([.fraction(0.25)])
        }
        .navigationDestination(isPresented: $isEditing) {
            EditSetView(viewModel: viewModel, set: set)
        }
    }
}
