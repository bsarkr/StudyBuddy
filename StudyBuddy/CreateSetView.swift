//
//  CreateSetView.swift
//  StudyBuddy
//
//  Created by Max Hazelton on 4/24/25.
//

import SwiftUI
import FirebaseAuth

struct CreateSetView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: SetViewModel

    @State private var title: String = ""
    @State private var terms: [FlashcardTerm] = [FlashcardTerm(term: "", definition: "")]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pink.opacity(0.1).edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    TextField("Set Title", text: $title)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(10)
                        .padding(.horizontal)

                    List {
                        ForEach($terms.indices, id: \.self) { index in
                            VStack(alignment: .leading) {
                                TextField("Term", text: $terms[index].term)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                TextField("Definition", text: $terms[index].definition)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            .padding(.vertical, 5)
                        }
                        .onDelete(perform: deleteTerm)

                        Button(action: {
                            terms.append(FlashcardTerm(term: "", definition: ""))
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Term")
                            }
                            .foregroundColor(.pink)
                        }
                    }
                    .listStyle(PlainListStyle())

                    Button(action: saveSet) {
                        Text("Save Set")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.pink)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }

                    Spacer()
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
                dismiss()
            }
        }

    }

    func deleteTerm(at offsets: IndexSet) {
        terms.remove(atOffsets: offsets)
    }
}

