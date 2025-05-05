//
//  EditSetView.swift
//  StudyBuddy
//
//  Created by Max Hazelton on 5/5/25.
//

import SwiftUI
import FirebaseAuth

struct EditSetView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: SetViewModel

    let existingSet: StudySet
    @State private var title: String
    @State private var terms: [FlashcardTerm]

    init(viewModel: SetViewModel, set: StudySet) {
        self.viewModel = viewModel
        self.existingSet = set
        _title = State(initialValue: set.title)
        _terms = State(initialValue: set.terms)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.pink.opacity(0.15).ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer().frame(height: 60)

                Text("Edit Study Set")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.pink)
                    .padding(.horizontal)

                TextField("Set Title", text: $title)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.pink.opacity(0.4), lineWidth: 1))
                    .padding(.horizontal)

                List {
                    ForEach($terms.indices, id: \.self) { index in
                        FlashcardTermView(term: $terms[index])
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteTerm(at: IndexSet(integer: index))
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }

                    Section(footer:
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    terms.append(FlashcardTerm(term: "", definition: ""))
                                }
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Term")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.pink.opacity(0.8))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .shadow(color: .pink.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            .frame(maxWidth: 600)
                            .padding(.horizontal)
                            Spacer()
                        }
                        .padding(.top, 12)
                    ) {}
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)

                Button(action: saveChanges) {
                    Text("Save Changes")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.pink)
                        .cornerRadius(15)
                        .shadow(color: .pink.opacity(0.3), radius: 5, x: 0, y: 3)
                        .padding(.horizontal)
                }

                Spacer()
            }

            // Cancel button (top left)
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
        }
        .navigationBarBackButtonHidden(true)
    }

    func saveChanges() {
        guard !title.isEmpty else { return }

        let id = existingSet.id
        var termDict: [String: String] = [:]

        for card in terms {
            if !card.term.isEmpty && !card.definition.isEmpty {
                termDict[card.term] = card.definition
            }
        }

        viewModel.updateSet(id: id, title: title, terms: termDict, userId: existingSet.userId)
        dismiss()
    }

    func deleteTerm(at offsets: IndexSet) {
        withAnimation {
            terms.remove(atOffsets: offsets)
        }
    }
}
