//
//  SetDetailView.swift
//  StudyBuddy
//
//  Created by Max Hazelton on 5/4/25.
//

import SwiftUI

struct SetDetailView: View {
    let set: StudySet

    @EnvironmentObject var viewModel: SetViewModel
    @Environment(\.dismiss) var dismiss
    @State private var isEditing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(set.title)
                .font(.largeTitle)
                .bold()
                .padding(.bottom)

            if set.terms.isEmpty {
                Text("No terms in this set.")
                    .foregroundColor(.gray)
            } else {
                List(set.terms, id: \.id) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.term)
                            .font(.headline)
                        Text(item.definition)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.insetGrouped)
            }

            Spacer()

            Button("Learn") {
                // Future: Navigate to game mode screen
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.pink)
            .foregroundColor(.white)
            .cornerRadius(12)

            HStack(spacing: 16) {
                Button("Edit") {
                    isEditing = true
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)

                Button("Delete") {
                    viewModel.deleteSet(set)
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            NavigationLink(
                destination: EditSetView(viewModel: viewModel, set: set),
                isActive: $isEditing
            ) {
                EmptyView()
            }
        }
        .padding()
        .navigationTitle("Set Details")
    }
}




