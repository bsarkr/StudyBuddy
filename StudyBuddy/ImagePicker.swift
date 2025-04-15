//
//  ImagePicker.swift
//  StudyBuddy
//
//  Created by Bilash Sarkar on 4/15/25.
//

import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @Binding var image: UIImage?

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let selectedImage = info[.originalImage] as? UIImage {
                let flipped = picker.cameraDevice == .front
                let finalImage = flipped ? selectedImage.flippedHorizontally() : selectedImage.fixedOrientation()
                parent.image = finalImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType

        if sourceType == .camera {
            picker.cameraDevice = .front
        }

        picker.modalPresentationStyle = .overFullScreen //Forces immersive full screen
        picker.view.backgroundColor = .black //Fills top/bottom with black
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

extension UIImage {
    // Flip horizontally for selfies
    func flippedHorizontally() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: size.width, y: 0)
        context?.scaleBy(x: -1, y: 1)
        draw(in: CGRect(origin: .zero, size: size))
        let flipped = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return flipped ?? self
    }

    // Normalize image orientation
    func fixedOrientation() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalized ?? self
    }
}
