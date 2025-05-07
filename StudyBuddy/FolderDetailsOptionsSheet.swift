//
//  FolderDetailsOptionsSheet.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/6/25.
//

import SwiftUI

struct FolderDetailsOptionsSheet: View {
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .frame(width: 40, height: 5)
                .foregroundColor(.gray.opacity(0.3))
                .padding(.top, 10)

            Button(action: onEdit) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Edit Folder")
                }
                .font(.headline)
                .foregroundColor(.pink)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(14)
                .shadow(color: .pink.opacity(0.2), radius: 3, x: 0, y: 2)
            }

            Button(action: onDelete) {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Folder")
                }
                .font(.headline)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(14)
                .shadow(color: .red.opacity(0.2), radius: 3, x: 0, y: 2)
            }

            Spacer()
        }
        .padding()
        .background(Color(red: 0.9, green: 0.85, blue: 1.0))
        .cornerRadius(30)
        .ignoresSafeArea(edges: .bottom)
    }
}
