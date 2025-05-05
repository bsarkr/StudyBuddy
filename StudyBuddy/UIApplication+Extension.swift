//
//  UIApplication+Extension.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 5/4/25.
//

import SwiftUI

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
