//
//  SocialView.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/4/25.
//

import SwiftUI

struct SocialView: View {
    @State private var selectedTab: String = "Messages"
    private let tabs = ["Friends", "Messages", "Sessions"]

    var body: some View {
        ZStack {
            Color.pink.opacity(0.1).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header
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

                // Tab Picker
                Picker("", selection: $selectedTab) {
                    ForEach(tabs, id: \.self) { tab in
                        Text(tab).tag(tab)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // Content Area
                Group {
                    if selectedTab == "Friends" {
                        FriendsTabView()
                    } else if selectedTab == "Messages" {
                        MessagingView()
                    } else if selectedTab == "Sessions" {
                        ScrollView {
                            VStack(spacing: 20) {
                                Text("Sessions View")
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
        }
    }
}

struct SocialView_Previews: PreviewProvider {
    static var previews: some View {
        SocialView()
            .environmentObject(AuthViewModel())
    }
}
