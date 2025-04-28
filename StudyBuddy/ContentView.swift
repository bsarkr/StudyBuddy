//
//  ContentView.swift
//  StudyBuddy
//
//  Created by Max Hazelton on 4/24/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        RootView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(AuthViewModel())
    }
}



