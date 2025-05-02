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
            // Use the edited image if available (cropped version)
            if let selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                if picker.sourceType == .camera {
                    let flipped = picker.cameraDevice == .front
                    let finalImage = flipped ? selectedImage.flippedHorizontally() : selectedImage.fixedOrientation()
                    parent.image = finalImage
                } else {
                    parent.image = selectedImage.fixedOrientation()
                }
            }

            // Delay dismissal slightly
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [self] in
                parent.presentationMode.wrappedValue.dismiss()
            }
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

        picker.allowsEditing = true  // 💥 Enables cropping
        picker.modalPresentationStyle = .fullScreen
        picker.view.backgroundColor = .black
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

extension UIImage {
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

    func fixedOrientation() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalized ?? self
    }
}
