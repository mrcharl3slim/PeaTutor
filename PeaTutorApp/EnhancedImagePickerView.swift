//
//  EnhancedImagePickerView.swift
//  PeaTutorApp
//
//  Created by Charles on 28/9/25.
//

import SwiftUI
import UIKit
import AVFoundation
import Photos

// MARK: - Image Source Type
enum ImageSourceType: String, CaseIterable {
    case camera = "Camera"
    case photoLibrary = "Photo Library"
    
    var systemImage: String {
        switch self {
        case .camera: return "camera"
        case .photoLibrary: return "photo.on.rectangle"
        }
    }
    
    var sourceType: UIImagePickerController.SourceType {
        switch self {
        case .camera: return .camera
        case .photoLibrary: return .photoLibrary
        }
    }
}

// MARK: - Enhanced Image Picker View with Native Editing
struct EnhancedImagePickerView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    let sourceType: ImageSourceType
    let onImageSelected: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType.sourceType
        
        // Enable built-in editing (crop/rotate)
        picker.allowsEditing = true
        
        if sourceType == .camera {
            picker.cameraCaptureMode = .photo
            picker.cameraDevice = .rear
            picker.cameraFlashMode = .auto
            
            // Add camera overlay for guidance
            if let overlayView = createCameraOverlay() {
                picker.cameraOverlayView = overlayView
            }
        } else {
            picker.mediaTypes = ["public.image"]
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
        let parent: EnhancedImagePickerView
        
        init(_ parent: EnhancedImagePickerView) {
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
                let processedImage = processImageForOCR(image)
                parent.onImageSelected(processedImage)
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

// MARK: - Image Source Selection Sheet
struct ImageSourceSelectionSheet: View {
    @Binding var isPresented: Bool
    let onSourceSelected: (ImageSourceType) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Image(systemName: "photo.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Add Worksheet Image")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Choose how you'd like to add your math worksheet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                
                VStack(spacing: 16) {
                    // Camera Option
                    ImageSourceButton(
                        sourceType: .camera,
                        isAvailable: ImagePermissionHelper.isCameraAvailable(),
                        onTap: { onSourceSelected(.camera) }
                    )
                    
                    // Photo Library Option
                    ImageSourceButton(
                        sourceType: .photoLibrary,
                        isAvailable: true,
                        onTap: { onSourceSelected(.photoLibrary) }
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Tips Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tips for Best Results:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TipText("📱 Hold device steady and ensure good lighting")
                        TipText("📄 Frame the entire worksheet clearly")
                        TipText("✂️ You can crop and adjust after capture")
                        TipText("📐 Position worksheet flat without shadows")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Add Image")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    isPresented = false
                }
            )
        }
    }
}

// MARK: - Image Source Button
struct ImageSourceButton: View {
    let sourceType: ImageSourceType
    let isAvailable: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            if isAvailable {
                onTap()
            }
        }) {
            HStack(spacing: 16) {
                Image(systemName: sourceType.systemImage)
                    .font(.title2)
                    .foregroundColor(isAvailable ? .blue : .gray)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(sourceType.rawValue)
                        .font(.headline)
                        .foregroundColor(isAvailable ? .primary : .secondary)
                    
                    Text(descriptionText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isAvailable {
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isAvailable ? Color(.systemBackground) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isAvailable ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isAvailable)
        .opacity(isAvailable ? 1.0 : 0.6)
    }
    
    private var descriptionText: String {
        switch sourceType {
        case .camera:
            return isAvailable ? "Take a photo and crop it" : "Camera not available"
        case .photoLibrary:
            return "Choose and edit from saved photos"
        }
    }
}

// MARK: - Tip Text Component
struct TipText: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
            .lineLimit(nil)
    }
}

// MARK: - Enhanced Permission Helper
struct ImagePermissionHelper {
    static func isCameraAvailable() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.camera) &&
               UIImagePickerController.isCameraDeviceAvailable(.rear)
    }
    
    static func isPhotoLibraryAvailable() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
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
    
    static func requestPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let authStatus = PHPhotoLibrary.authorizationStatus()
        
        switch authStatus {
        case .authorized, .limited:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    completion(status == .authorized || status == .limited)
                }
            }
        @unknown default:
            completion(false)
        }
    }
    
    static func getCameraPermissionStatus() -> String {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch authStatus {
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not Determined"
        @unknown default: return "Unknown"
        }
    }
    
    static func getPhotoLibraryPermissionStatus() -> String {
        let authStatus = PHPhotoLibrary.authorizationStatus()
        
        switch authStatus {
        case .authorized: return "Authorized"
        case .limited: return "Limited"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not Determined"
        @unknown default: return "Unknown"
        }
    }
}
