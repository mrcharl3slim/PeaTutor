//
//  CameraCaptureView.swift
//  PeaTutorApp
//
//  Created by Charles on 27/9/25.
//

import SwiftUI
import UIKit
import AVFoundation

// MARK: - Camera Capture View with Native Editing
struct CameraCaptureView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    let onImageCaptured: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.cameraDevice = .rear
        
        // Optimize for document capture
        picker.cameraFlashMode = .auto
        
        // Enable built-in editing (crop/rotate)
        picker.allowsEditing = true
        
        // Add overlay text for better user guidance
        if let overlayView = createCameraOverlay() {
            picker.cameraOverlayView = overlayView
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func createCameraOverlay() -> UIView? {
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.clear
        
        // Add guidance text at the top
        let label = UILabel()
        label.text = "Position worksheet in frame"
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        
        overlayView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            label.topAnchor.constraint(equalTo: overlayView.safeAreaLayoutGuide.topAnchor, constant: 20),
            label.widthAnchor.constraint(equalToConstant: 250),
            label.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        return overlayView
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraCaptureView
        
        init(_ parent: CameraCaptureView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // Try to get edited image first, fallback to original
            var selectedImage: UIImage?
            
            if let editedImage = info[.editedImage] as? UIImage {
                print("✂️ Using edited (cropped) image")
                selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                print("📸 Using original image (no edits made)")
                selectedImage = originalImage
            }
            
            if let image = selectedImage {
                // Process image for better OCR quality
                let processedImage = processImageForOCR(image)
                parent.onImageCaptured(processedImage)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        private func processImageForOCR(_ image: UIImage) -> UIImage {
            // Ensure image is properly oriented
            if image.imageOrientation == .up {
                return image
            }
            
            // Redraw image with correct orientation
            UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
            image.draw(in: CGRect(origin: .zero, size: image.size))
            let orientedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
            
            return orientedImage
        }
    }
}

// MARK: - Camera Permission Helper
struct CameraPermissionHelper {
    static func checkCameraPermission() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    static func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch authStatus {
        case .authorized:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        @unknown default:
            completion(false)
        }
    }
    
    static func getCameraPermissionStatus() -> String {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch authStatus {
        case .authorized:
            return "Authorized"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        case .notDetermined:
            return "Not Determined"
        @unknown default:
            return "Unknown"
        }
    }
    
    static func isCameraAvailable() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.camera) &&
               UIImagePickerController.isCameraDeviceAvailable(.rear)
    }
}
