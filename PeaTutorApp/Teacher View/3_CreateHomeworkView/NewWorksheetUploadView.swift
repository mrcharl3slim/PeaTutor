//
//  NewWorksheetUploadView.swift
//  PeaTutorApp
//
//  Sprint 5 Phase 1: Embedded worksheet upload for homework creation
//  Reuses existing ContentView upload logic in a contained component
//

import SwiftUI
import Amplify

struct NewWorksheetUploadView: View {
    @StateObject private var vm = ExtractViewModel()
    @Environment(\.dismiss) var dismiss
    
    let onWorksheetUploaded: (Worksheet) -> Void
    let onCancel: () -> Void
    
    // Upload state
    @State private var pickedURLs: [URL] = []
    @State private var capturedImages: [UIImage] = []
    @State private var showingImporter = false
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var showingPhotoOptions = false
    
    // Success state
    @State private var uploadComplete = false
    @State private var extractedWorksheet: Worksheet?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main content
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Upload options
                        if !vm.isLoading && !uploadComplete {
                            uploadOptionsSection
                        }
                        
                        // File previews
                        if !pickedURLs.isEmpty || !capturedImages.isEmpty {
                            filePreviewSection
                        }
                        
                        // Extract button
                        if !pickedURLs.isEmpty || !capturedImages.isEmpty, !vm.isLoading, !uploadComplete {
                            extractButton
                        }
                        
                        // Progress
                        if vm.isLoading {
                            loadingSection
                        }
                        
                        // Success
                        if uploadComplete {
                            successSection
                        }
                    }
                    .padding()
                }
                
                // Duplicate alert overlay
                if vm.showingDuplicateAlert, let duplicate = vm.duplicateDetected {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    DuplicateBlockedView(
                        duplicateExtraction: duplicate,
                        onUseExisting: {
                            Task { await useExistingWorksheet(duplicate) }
                        },
                        onReExtract: {
                            Task { await forceReExtract() }
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
            .navigationTitle("Upload Worksheet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
        // File importer
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.pdf, .plainText, .jpeg, .png],
            allowsMultipleSelection: true
        ) { result in
            handleFileSelection(result: result)
        }
        // Image source selection sheet
        .confirmationDialog("Add Images", isPresented: $showingPhotoOptions) {
            Button("Take Photo") { showingCamera = true }
            Button("Choose from Photos") { showingPhotoPicker = true }
            Button("Cancel", role: .cancel) {}
        }
        // Camera
        .fullScreenCover(isPresented: $showingCamera) {
            CameraCaptureView { image in
                capturedImages.append(image)
            }
        }

        // Photo picker
        .fullScreenCover(isPresented: $showingPhotoPicker) {
            SimplePhotoPickerView { image in
                capturedImages.append(image)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: uploadComplete ? "checkmark.circle.fill" : "doc.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(uploadComplete ? .green : .blue)
            
            Text(uploadComplete ? "Upload Complete!" : "Upload New Worksheet")
                .font(.title2.bold())
            
            Text(uploadComplete ? 
                 "Questions extracted successfully" :
                 "Add a worksheet to assign as homework")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }
    
    // MARK: - Upload Options Section
    
    private var uploadOptionsSection: some View {
        VStack(spacing: 16) {
            // Import files button
            Button {
                showingImporter = true
            } label: {
                HStack {
                    Image(systemName: "tray.and.arrow.down.fill")
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Import Files")
                            .font(.headline)
                        Text("PDF, DOCX, or Images")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1.5)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Camera/Photo button
            Button {
                showingPhotoOptions = true
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Take Photo or Choose from Library")
                            .font(.headline)
                        Text("Capture or select images")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1.5)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Tips
            VStack(alignment: .leading, spacing: 8) {
                Label("Tips for Best Results:", systemImage: "lightbulb.fill")
                    .font(.subheadline.bold())
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    TipRow(emoji: "📖", text: "Ensure good lighting and clear text")
                    TipRow(emoji: "📖", text: "Frame the entire worksheet")
                    TipRow(emoji: "📖", text: "Avoid shadows and glare")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // MARK: - File Preview Section
    
    private var filePreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Selected Files (\(pickedURLs.count + capturedImages.count))")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // File previews
                    ForEach(pickedURLs, id: \.self) { url in
                        FilePreviewCard(url: url) {
                            removeFile(url)
                        }
                    }
                    
                    // Image previews
                    ForEach(capturedImages.indices, id: \.self) { index in
                        ImagePreviewCard(
                            image: capturedImages[index],
                            title: "Image \(index + 1)"
                        ) {
                            removeImage(at: index)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Extract Button
    
    private var extractButton: some View {
        Button {
            Task {
                await extractWorksheet()
            }
        } label: {
            HStack {
                Image(systemName: "sparkles")
                Text("Extract Questions")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Loading Section
    
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView(value: vm.progress) {
                Text(progressText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .progressViewStyle(.linear)
            
            if vm.progress > 0 {
                Text("\(Int(vm.progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var progressText: String {
        if vm.progress < 0.3 {
            return "Uploading files..."
        } else if vm.progress < 0.7 {
            return "Processing with AI..."
        } else if vm.progress < 1.0 {
            return "Saving worksheet..."
        } else {
            return "Complete!"
        }
    }
    
    // MARK: - Success Section
    
    private var successSection: some View {
        VStack(spacing: 20) {
            if let worksheet = extractedWorksheet {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Worksheet Ready!")
                        .font(.title2.bold())
                    
                    Text("\(worksheet.questionCount ?? 0) questions extracted")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Worksheet preview card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.blue)
                            Text(worksheet.title)
                                .font(.headline)
                                .lineLimit(2)
                        }
                        
                        HStack {
                            Label("\(worksheet.questionCount ?? 0) questions", 
                                  systemImage: "list.number")
                            Spacer()
                            if let marks = worksheet.totalMarks {
                                Label("\(marks) marks", 
                                      systemImage: "star.fill")
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                Button {
                    onWorksheetUploaded(worksheet)
                    dismiss()
                } label: {
                    Text("Use This Worksheet")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func handleFileSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            pickedURLs.append(contentsOf: urls)
        case .failure(let error):
            print("❌ File selection error: \(error)")
        }
    }
    
    private func removeFile(_ url: URL) {
        pickedURLs.removeAll { $0 == url }
    }
    
    private func removeImage(at index: Int) {
        capturedImages.remove(at: index)
    }
    
    private func extractWorksheet() async {
        // Check for duplicates first
        let isDuplicate = await vm.checkForDuplicatesAndExtract(
            fileURLs: pickedURLs,
            capturedImages: capturedImages
        )
        
        // If duplicate detected, alert is shown automatically
        // User can choose to use existing or re-extract
        if !isDuplicate {
            await vm.runExtraction(
                fileURLs: pickedURLs,
                capturedImages: capturedImages
            )
            
            // After extraction, fetch the saved worksheet
            if let worksheetId = vm.lastSavedWorksheetId {
                await loadExtractedWorksheet(worksheetId)
            }
        }
    }
    
    private func loadExtractedWorksheet(_ worksheetId: String) async {
        do {
            if let worksheet = try await Amplify.DataStore.query(
                Worksheet.self,
                byId: worksheetId
            ) {
                await MainActor.run {
                    extractedWorksheet = worksheet
                    uploadComplete = true
                }
            }
        } catch {
            print("❌ Failed to load worksheet: \(error)")
        }
    }
    
    private func useExistingWorksheet(_ duplicate: ExtractionHistory) async {
        // User chose to use the existing worksheet instead of re-extracting
        if let worksheetId = duplicate.datastoreWorksheetId {
            await loadExtractedWorksheet(worksheetId)
        }
        vm.showingDuplicateAlert = false
    }
    
    private func forceReExtract() async {
        // User chose to re-extract anyway
        vm.showingDuplicateAlert = false
        
        // Run extraction without duplicate check
        await vm.runExtraction(
            fileURLs: pickedURLs,
            capturedImages: capturedImages
        )
        
        // Load the newly extracted worksheet
        if let worksheetId = vm.lastSavedWorksheetId {
            await loadExtractedWorksheet(worksheetId)
        }
    }
}

// MARK: - Supporting Views

struct TipRow: View {
    let emoji: String
    let text: String
   
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: emoji)
                .font(.caption)
                .foregroundColor(.green)
            Text(text)
        }
    }
}
