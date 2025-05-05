//
//  Social.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/4/25.

import SwiftUI

struct SocialView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                Color.pink.ignoresSafeArea(edges: .top)
                Text("Social")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.leading)
                    .padding(.bottom, 10)
            }
            .frame(height: 70)

            ScrollView {
                VStack(spacing: 20) {
                    Text("WORK IN PROGRESS")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .padding(.top, 40)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct SocialView_Previews: PreviewProvider {
    static var previews: some View {
        SocialView()
    }
}
