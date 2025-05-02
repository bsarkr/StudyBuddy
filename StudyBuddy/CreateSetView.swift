//
//  CreateSetView.swift
//  StudyBuddy
//
//  Created by Max Hazelton on 4/24/25.
//  Edited by Bilash Sarkar on 5/2/25.
//

import SwiftUI
import FirebaseAuth

struct CreateSetView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: SetViewModel

    @Binding var didSaveExternally: Bool
    @State private var showingAI = false

    @State private var title: String = ""
    @State private var terms: [FlashcardTerm] = [FlashcardTerm(term: "", definition: "")]
    @Namespace private var animationNamespace

    init(
        viewModel: SetViewModel,
        title: String = "",
        terms: [FlashcardTerm] = [FlashcardTerm(term: "", definition: "")],
        didSaveExternally: Binding<Bool> = .constant(false)
    ) {
        self.viewModel = viewModel
        _title = State(initialValue: title)
        _terms = State(initialValue: terms)
        _didSaveExternally = didSaveExternally
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pink.opacity(0.15).ignoresSafeArea()

                VStack(spacing: 20) {
                    Button(action: {
                        showingAI = true
                    }) {
                        Text("Use AI to Generate Terms")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .background(Color.pink.opacity(0.8))
                            .cornerRadius(12)
                            .shadow(color: .pink.opacity(0.2), radius: 3, x: 0, y: 2)
                    }
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

                    Button(action: saveSet) {
                        Text("Save Set")
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
            }
            .navigationTitle("New Study Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.pink)
                }
            }
            .sheet(isPresented: $showingAI) {
                AISetBuilderView(
                        title: $title,
                        terms: $terms,
                        didSaveSet: $didSaveExternally,
                        setViewModel: viewModel
                    )
            }
        }
    }

    func saveSet() {
        guard !title.isEmpty else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }

        var termDict: [String: String] = [:]
        for card in terms {
            if !card.term.isEmpty && !card.definition.isEmpty {
                termDict[card.term] = card.definition
            }
        }

        viewModel.saveSet(title: title, terms: termDict, userId: uid) { error in
            if let error = error {
                print("Failed to save set: \(error.localizedDescription)")
            } else {
                print("Set saved successfully!")
                didSaveExternally = true //notifing parent view to dismiss
                dismiss()
            }
        }
    }

    func deleteTerm(at offsets: IndexSet) {
        withAnimation {
            terms.remove(atOffsets: offsets)
        }
    }
}

struct FlashcardTermView: View {
    @Binding var term: FlashcardTerm

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("Enter term", text: $term.term)
                .padding(.vertical, 6)
                .overlay(Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.pink.opacity(0.5)), alignment: .bottom)

            Text("Term")
                .font(.caption)
                .foregroundColor(.pink.opacity(0.7))

            TextField("Enter definition", text: $term.definition)
                .padding(.vertical, 6)
                .overlay(Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.pink.opacity(0.5)), alignment: .bottom)

            Text("Definition")
                .font(.caption)
                .foregroundColor(.pink.opacity(0.7))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(18)
        .padding(.vertical, 6)
        .padding(.horizontal)
    }
}
