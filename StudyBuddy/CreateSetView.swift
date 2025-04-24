//
//  CreateSetView.swift
//  StudyBuddy
//
//  Created by Max Hazelton on 4/24/25.
//

struct CreateSetView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: SetViewModel
    @State private var title: String = ""
    @State private var terms: [FlashcardTerm] = [FlashcardTerm(term: "", definition: "")]
    
    var body: some View {
        NavigationStack {
            VStack {
                TextField("Set Title", text: $title)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.horizontal)

                List {
                    ForEach(terms.indices, id: \.self) { i in
                        VStack(alignment: .leading) {
                            TextField("Term", text: $terms[i].term)
                            TextField("Definition", text: $terms[i].definition)
                        }
                    }
                    .onDelete { terms.remove(atOffsets: $0) }

                    Button("Add Term") {
                        terms.append(FlashcardTerm(term: "", definition: ""))
                    }
                }

                Button("Save") {
                    guard let uid = Auth.auth().currentUser?.uid else { return }
                    let newSet = StudySet(title: title, terms: terms, userId: uid)
                    viewModel.addSet(newSet)
                    dismiss()
                }
                .padding()
                .background(Color.pink)
                .foregroundColor(.white)
                .cornerRadius(12)

                Spacer()
            }
            .navigationTitle("New Set")
        }
    }
}
