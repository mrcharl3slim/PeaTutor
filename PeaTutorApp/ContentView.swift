//
//  ContentView_Updates_3.3.swift
//  PeaTutorApp
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var vm = ExtractViewModel()
    @StateObject private var aws = AWSService.shared
    
    @State private var showingImporter = false
    @State private var showingImageFlow = false
    @State private var showingPermissionAlert = false
    @State private var showingCloudStorage = false
    @State private var permissionAlertMessage = ""
    @State private var pickedURLs: [URL] = []
    @State private var capturedImages: [UIImage] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // User info bar
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome back!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if let username = aws.currentUser?.username {
                            Text(username)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            try? await aws.signOut()
                        }
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Toggle("Mock Mode (offline)", isOn: $vm.mockMode)
                    .padding(.horizontal)
                
                Divider()
                
                // Add this button temporarily in ContentView
                Button("Reset All") {
                    UserDefaults.standard.removeObject(forKey: "HasDeletedSwiftDataStoreV1")
                    UserDefaults.standard.removeObject(forKey: "HasDeletedSwiftDataStoreV2")
                    UserDefaults.standard.removeObject(forKey: "HasClearedDataStoreV1")
                    print("✅ Reset all flags")
                }
                .foregroundColor(.red)

                // Quick Actions Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Actions")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // 🆕 View Saved Worksheets (NEW)
                        NavigationLink {
                            SavedWorksheetsView()
                        } label: {
                            HStack {
                                Image(systemName: "doc.text.fill")  // Database icon
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Saved Worksheets")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("View extracted questions")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))  // Blue for database
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                    
                    // View Extraction History button
                    NavigationLink {
                        HistoryView()
                    } label: {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("View Extraction History")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    
                    Button {
                        showingCloudStorage = true
                    } label: {
                        HStack {
                            Image(systemName: "cloud.fill")
                            Text("View Cloud Storage")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                }

                // Import options section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add New Worksheet")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        Button {
                            showingImporter = true
                        } label: {
                            Label("Import Files (PDF / DOCX / Images)", systemImage: "tray.and.arrow.down")
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            showingImageFlow = true
                        } label: {
                            Label("Add Images from Camera or Photos", systemImage: "camera.badge.ellipsis")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                }

                // Display selected files
                if !pickedURLs.isEmpty || !capturedImages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(pickedURLs, id: \.self) { url in
                                FilePreviewCard(url: url) {
                                    removeFile(url)
                                }
                            }
                            
                            ForEach(capturedImages.indices, id: \.self) { index in
                                ImagePreviewCard(
                                    image: capturedImages[index],
                                    title: "Image \(index + 1)"
                                ) {
                                    removeImage(at: index)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // ✅ FIXED: Run extraction button - Call runExtraction directly
                Button {
                    Task {
                        // Clear previous save status
                        vm.lastSavedWorksheetId = nil
                        
                        // Check for duplicates first
                        let isDuplicate = await vm.checkForDuplicatesAndExtract(
                            fileURLs: pickedURLs,
                            capturedImages: capturedImages
                        )
                        
                        // Only proceed if not a duplicate
                        if !isDuplicate {
                            // ✅ Call runExtraction (it already includes DataStore persistence)
                            await vm.runExtraction(
                                fileURLs: pickedURLs,
                                capturedImages: capturedImages
                            )
                        }
                    }
                } label: {
                    HStack {
                        if vm.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Label("Extract Questions", systemImage: "sparkles")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(pickedURLs.isEmpty && capturedImages.isEmpty)

                // Progress bar
                ProgressView(value: vm.progress)
                    .opacity(vm.isLoading ? 1 : 0)
                    .padding(.horizontal)

                // Success indicator
                if let worksheetId = vm.lastSavedWorksheetId {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("✅ Saved to history")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("ID: \(worksheetId.prefix(8))...")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    .transition(.opacity.combined(with: .scale))
                }

                // Results navigation
                if let result = vm.result {
                    NavigationLink {
                        JSONPreviewView(result: result, savedWorksheetId: vm.lastSavedWorksheetId)
                    } label: {
                        Label("View Parsed Questions (\(result.questions.count))", systemImage: "list.bullet.rectangle")
                    }
                    .buttonStyle(.borderedProminent)
                }

                Spacer()
                
                // Status information
                if vm.isLoading {
                    VStack(spacing: 8) {
                        Text("Processing \(pickedURLs.count + capturedImages.count) item(s)...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if vm.progress > 0 {
                            Text("\(Int(vm.progress * 100))% complete")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("MagicMaths")
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.pdf, .plainText, .image, UTType(filenameExtension: "docx")!],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                pickedURLs.append(contentsOf: urls)
            case .failure(let error):
                print("File import error: \(error)")
            }
        }
        .sheet(isPresented: $showingImageFlow) {
            ImageFlowView(
                isPresented: $showingImageFlow,
                onImageSelected: { image in
                    capturedImages.append(image)
                },
                onPermissionDenied: { message in
                    permissionAlertMessage = message
                    showingPermissionAlert = true
                }
            )
        }
        .sheet(isPresented: $showingCloudStorage) {
            NavigationView {
                StoredFilesView()
            }
        }
        .alert("Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(permissionAlertMessage)
        }
        // Duplicate detection alert
        .overlay {
            if vm.showingDuplicateAlert, let duplicate = vm.duplicateDetected {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                DuplicateBlockedView(
                    duplicateExtraction: duplicate,
                    onUseExisting: {
                        // Navigate to existing worksheet in history
                        vm.showingDuplicateAlert = false
                        // Show history view with this worksheet
                        vm.duplicateDetected = nil
                    },
                    onReExtract: {
                        // Allow re-extraction
                        vm.showingDuplicateAlert = false
                        Task {
                            await vm.runExtraction(
                                fileURLs: pickedURLs,
                                capturedImages: capturedImages
                            )
                        }
                    },
                    onCancel: {
                        vm.showingDuplicateAlert = false
                        vm.duplicateDetected = nil
                    }
                )
                .frame(maxWidth: 400)
                .padding()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func removeFile(_ url: URL) {
        withAnimation {
            pickedURLs.removeAll { $0 == url }
        }
    }
    
    private func removeImage(at index: Int) {
        withAnimation {
            capturedImages.remove(at: index)
        }
    }
}

// MARK: - Unified Image Flow View
struct ImageFlowView: View {
    @Binding var isPresented: Bool
    let onImageSelected: (UIImage) -> Void
    let onPermissionDenied: (String) -> Void
    
    @State private var showingImagePicker = false
    @State private var selectedSourceType: ImageSourceType = .camera
    @State private var showingSourceSelection = true
    
    var body: some View {
        Group {
            if showingSourceSelection {
                // Source selection view
                ImageSourceSelectionView(
                    onSourceSelected: { sourceType in
                        selectedSourceType = sourceType
                        requestPermissionAndShowPicker(for: sourceType)
                    },
                    onCancel: {
                        isPresented = false
                    }
                )
            } else {
                // Image picker view
                EnhancedImagePickerView(sourceType: selectedSourceType) { image in
                    onImageSelected(image)
                    isPresented = false
                }
            }
        }
    }
    
    private func requestPermissionAndShowPicker(for sourceType: ImageSourceType) {
        switch sourceType {
        case .camera:
            ImagePermissionHelper.requestCameraPermission { granted in
                if granted {
                    showingSourceSelection = false
                    showingImagePicker = true
                } else {
                    onPermissionDenied("Camera access is required to take photos of worksheets. Please enable camera access in Settings.")
                    isPresented = false
                }
            }
        case .photoLibrary:
            ImagePermissionHelper.requestPhotoLibraryPermission { granted in
                if granted {
                    showingSourceSelection = false
                    showingImagePicker = true
                } else {
                    onPermissionDenied("Photo library access is required to select existing photos. Please enable photo access in Settings.")
                    isPresented = false
                }
            }
        }
    }
}

// MARK: - Source Selection View
struct ImageSourceSelectionView: View {
    let onSourceSelected: (ImageSourceType) -> Void
    let onCancel: () -> Void
    
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
                        onTap: {
                            onSourceSelected(.camera)
                        }
                    )
                    
                    // Photo Library Option
                    ImageSourceButton(
                        sourceType: .photoLibrary,
                        isAvailable: true,
                        onTap: {
                            onSourceSelected(.photoLibrary)
                        }
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
                        TipText("📏 Make sure all text and equations are readable")
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
                    onCancel()
                }
            )
        }
    }
}

// MARK: - File Preview Card
struct FilePreviewCard: View {
    let url: URL
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .background(Color.white, in: Circle())
                }
                .offset(x: 8, y: -8)
            }
            
            VStack(spacing: 4) {
                Image(systemName: fileIcon)
                    .font(.title)
                    .foregroundColor(.blue)
                
                Text(url.lastPathComponent)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 80)
            }
        }
        .frame(width: 100, height: 100)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1.5)
                .background(Color.blue.opacity(0.05))
        )
        .cornerRadius(12)
    }
    
    private var fileIcon: String {
        switch url.pathExtension.lowercased() {
        case "pdf": return "doc.richtext"
        case "docx": return "doc.text"
        case "jpg", "jpeg", "png": return "photo"
        default: return "doc"
        }
    }
}

// MARK: - Image Preview Card
struct ImagePreviewCard: View {
    let image: UIImage
    let title: String
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .background(Color.white, in: Circle())
                }
                .offset(x: 8, y: -8)
            }
            
            VStack(spacing: 4) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipped()
                    .cornerRadius(8)
                
                Text(title)
                    .font(.caption)
                    .lineLimit(1)
            }
        }
        .frame(width: 100, height: 100)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 1.5)
                .background(Color.green.opacity(0.05))
        )
        .cornerRadius(12)
    }
}
