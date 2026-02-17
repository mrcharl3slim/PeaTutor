//
//  LocalSolutionFeedback.swift
//  PeaTutorApp
//
//  Sub-Sprint 3.4: Enhanced with DataStore sync
//

import SwiftUI
import UIKit
import Amplify
import UniformTypeIdentifiers

// MARK: - Local Solution Feedback Model (UI Layer)
struct LocalSolutionFeedback: Identifiable {
    let id = UUID()
    let solutionImage: Data
    let feedback: String
    let isCorrect: Bool?
    let suggestions: [String]
    let timestamp: Date
    let attemptNumber: Int
    
    // DataStore ID (if synced)
    var datastoreId: String?
    var isSynced: Bool { datastoreId != nil }
    
    init(
        solutionImage: Data,
        feedback: String,
        isCorrect: Bool?,
        suggestions: [String],
        timestamp: Date = Date(),
        attemptNumber: Int = 1,
        datastoreId: String? = nil
    ) {
        self.solutionImage = solutionImage
        self.feedback = feedback
        self.isCorrect = isCorrect
        self.suggestions = suggestions
        self.timestamp = timestamp
        self.attemptNumber = attemptNumber
        self.datastoreId = datastoreId
    }
}

// MARK: - Solution Feedback View Model
@MainActor
class SolutionFeedbackViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showingError = false
    @Published var currentFeedback: LocalSolutionFeedback?
    @Published var feedbackHistory: [LocalSolutionFeedback] = []
    @Published var isSyncing = false
    
    let questionId: String
    let questionText: String
    let worksheetId: String
    
    init(questionId: String, questionText: String, worksheetId: String) {
        self.questionId = questionId
        self.questionText = questionText
        self.worksheetId = worksheetId
    }
    
    // MARK: - Load Feedback History
    
    func loadFeedbackHistory() async {
        print("📥 Loading feedback history for question: \(questionId)")
        
        do {
            let datastoreFeedback = try await DataStoreService.shared.fetchSolutionFeedback(
                forQuestionId: questionId,
                worksheetId: worksheetId
            )
            
            // Convert DataStore feedback to local model
            var history: [LocalSolutionFeedback] = []
            
            for feedback in datastoreFeedback {
                // Download solution image from S3
                if let imageData = try? await AWSService.shared.downloadFile(
                    key: feedback.s3SolutionImageKey
                ) {
                    let localFeedback = LocalSolutionFeedback(
                        solutionImage: imageData,
                        feedback: feedback.feedback,
                        isCorrect: feedback.isCorrect,
                        suggestions: feedback.suggestions?.compactMap { $0 } ?? [],
                        timestamp: feedback.submittedAt.foundationDate,
                        attemptNumber: feedback.attemptNumber,
                        datastoreId: feedback.id
                    )
                    history.append(localFeedback)
                }
            }
            
            await MainActor.run {
                self.feedbackHistory = history.sorted { $0.timestamp > $1.timestamp }
                print("✅ Loaded \(history.count) feedback attempt(s)")
            }
            
        } catch {
            print("⚠️ Failed to load feedback history: \(error)")
            await MainActor.run {
                errorMessage = "Could not load feedback history"
                showingError = true
            }
        }
    }
    
    // MARK: - Submit New Solution
    
    func submitSolution(_ image: UIImage) async {
        isLoading = true
        defer { isLoading = false }
        
        print("📤 Submitting solution for question: \(questionId)")
        
        do {
            // 1. Optimize image
            guard let imageData = image.jpegData(compressionQuality: 0.85) else {
                throw SolutionFeedbackError.imageProcessingFailed
            }
            
            // 2. Upload to S3
            isSyncing = true
            let s3Key = try await AWSService.shared.uploadSolutionImage(
                imageData,
                worksheetId: worksheetId,
                questionId: questionId
            )
            print("✅ Uploaded to S3: \(s3Key)")
            
            // 3. Get AI feedback
            guard let client = OpenAIClient() else {
                throw SolutionFeedbackError.openAIClientUnavailable
            }
            
            let aiResult = try await client.analyzeSolutionImage(
                questionText: questionText,
                solutionImageData: imageData
            )
            print("✅ AI feedback received")
            
            // 4. Save to DataStore
            let datastoreFeedback = try await DataStoreService.shared.saveSolutionFeedback(
                localFeedback: LocalSolutionFeedback(
                    solutionImage: imageData,
                    feedback: aiResult.feedback,
                    isCorrect: aiResult.isCorrect,
                    suggestions: aiResult.suggestions, // Already [String] from OpenAI
                    attemptNumber: feedbackHistory.count + 1
                ),
                s3ImageKey: s3Key,
                worksheetId: worksheetId,
                questionId: questionId
            )
            print("✅ Saved to DataStore: \(datastoreFeedback.id)")
            
            // 5. Create local feedback with DataStore ID
            let localFeedback = LocalSolutionFeedback(
                solutionImage: imageData,
                feedback: aiResult.feedback,
                isCorrect: aiResult.isCorrect,
                suggestions: aiResult.suggestions, // Already [String] from OpenAI
                attemptNumber: feedbackHistory.count + 1,
                datastoreId: datastoreFeedback.id
            )
            
            await MainActor.run {
                currentFeedback = localFeedback
                feedbackHistory.insert(localFeedback, at: 0)
                isSyncing = false
                print("🎉 Solution submitted successfully!")
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to submit solution: \(error.localizedDescription)"
                showingError = true
                isSyncing = false
                print("❌ Submission error: \(error)")
            }
        }
    }
}

// MARK: - Error Types
enum SolutionFeedbackError: Error, LocalizedError {
    case imageProcessingFailed
    case openAIClientUnavailable
    case uploadFailed
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Could not process image"
        case .openAIClientUnavailable:
            return "OpenAI client not available"
        case .uploadFailed:
            return "Failed to upload to cloud"
        case .saveFailed:
            return "Failed to save feedback"
        }
    }
}

// MARK: - Enhanced Feedback Button with History + Multiple Upload Sources
struct SolutionFeedbackButton: View {
    let questionId: String
    let questionText: String
    let worksheetId: String
    let isSubpart: Bool
    
    @StateObject private var viewModel: SolutionFeedbackViewModel
    @State private var showingSourcePicker = false
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var showingFilePicker = false
    @State private var showingHistory = false
    
    init(questionId: String, questionText: String, worksheetId: String, isSubpart: Bool = false) {
        self.questionId = questionId
        self.questionText = questionText
        self.worksheetId = worksheetId
        self.isSubpart = isSubpart
        
        _viewModel = StateObject(wrappedValue: SolutionFeedbackViewModel(
            questionId: questionId,
            questionText: questionText,
            worksheetId: worksheetId
        ))
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Submit new solution button (now with options)
                Button(action: {
                    showingSourcePicker = true
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "photo.badge.plus")
                                .font(.subheadline)
                        }
                        
                        Text(viewModel.isLoading ? "Getting Feedback..." : "Get Feedback")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, isSubpart ? 8 : 12)
                    .background(viewModel.isLoading ? Color.gray : Color.purple)
                    .cornerRadius(isSubpart ? 8 : 10)
                }
                .disabled(viewModel.isLoading)
                
                // History button
                if !viewModel.feedbackHistory.isEmpty {
                    Button(action: { showingHistory = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.caption)
                            Text("\(viewModel.feedbackHistory.count)")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.purple)
                        .padding(.horizontal, 12)
                        .padding(.vertical, isSubpart ? 8 : 12)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(isSubpart ? 8 : 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: isSubpart ? 8 : 10)
                                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
            
            // Sync indicator
            if viewModel.isSyncing {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Syncing to cloud...")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Current feedback display
            if let feedback = viewModel.currentFeedback {
                FeedbackResultCard(feedback: feedback)
            }
        }
        // Source picker dialog
        .confirmationDialog("Upload Your Solution", isPresented: $showingSourcePicker, titleVisibility: .visible) {
            Button("Take Photo") {
                requestCameraAndShow()
            }
            Button("Choose from Photos") {
                requestPhotosAndShow()
            }
            Button("Choose from Files") {
                showingFilePicker = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose how to upload your written work")
        }
        .fullScreenCover(isPresented: $showingCamera) {
            SimpleCameraView { capturedImage in
                Task {
                    await viewModel.submitSolution(capturedImage)
                }
            }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            SimplePhotoPickerView { selectedImage in
                Task {
                    await viewModel.submitSolutionFromPhotos(selectedImage)
                }
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.image, .jpeg, .png, .heic, .pdf],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result: result)
        }
        .sheet(isPresented: $showingHistory) {
            FeedbackHistoryView(
                viewModel: viewModel,
                questionId: questionId
            )
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .task {
            await viewModel.loadFeedbackHistory()
        }
    }
    
    // MARK: - Helper Methods
    
    private func requestCameraAndShow() {
        ImagePermissionHelper.requestCameraPermission { granted in
            if granted {
                showingCamera = true
            } else {
                viewModel.errorMessage = "Camera access is required to capture your solution."
                viewModel.showingError = true
            }
        }
    }
    
    private func requestPhotosAndShow() {
        ImagePermissionHelper.requestPhotoLibraryPermission { granted in
            if granted {
                showingPhotoPicker = true
            } else {
                viewModel.errorMessage = "Photo library access is required to select your solution."
                viewModel.showingError = true
            }
        }
    }
    
    private func handleFileSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            Task {
                await viewModel.submitSolutionFromFile(url)
            }
            
        case .failure(let error):
            viewModel.errorMessage = "File selection failed: \(error.localizedDescription)"
            viewModel.showingError = true
        }
    }
}

// MARK: - Feedback Result Card
struct FeedbackResultCard: View {
    let feedback: LocalSolutionFeedback
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundColor(iconColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(headerText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(iconColor)
                    
                    HStack(spacing: 8) {
                        Text("Attempt #\(feedback.attemptNumber)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if feedback.isSynced {
                            HStack(spacing: 3) {
                                Image(systemName: "checkmark.icloud.fill")
                                    .font(.caption2)
                                Text("Synced")
                                    .font(.caption2)
                            }
                            .foregroundColor(.green)
                        }
                    }
                }
                
                Spacer()
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Feedback text
            Text(feedback.feedback)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(isExpanded ? nil : 3)
            
            // Suggestions (when expanded)
            if isExpanded && !feedback.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Suggestions:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    ForEach(feedback.suggestions, id: \.self) { suggestion in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text(suggestion)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(backgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 2)
        )
    }
    
    private var iconName: String {
        if feedback.isCorrect == true {
            return "checkmark.circle.fill"
        } else if feedback.isCorrect == false {
            return "xmark.circle.fill"
        } else {
            return "info.circle.fill"
        }
    }
    
    private var iconColor: Color {
        if feedback.isCorrect == true {
            return .green
        } else if feedback.isCorrect == false {
            return .red
        } else {
            return .orange
        }
    }
    
    private var headerText: String {
        if feedback.isCorrect == true {
            return "Correct! ✓"
        } else if feedback.isCorrect == false {
            return "Needs Improvement"
        } else {
            return "Review Feedback"
        }
    }
    
    private var backgroundColor: Color {
        if feedback.isCorrect == true {
            return Color.green.opacity(0.05)
        } else if feedback.isCorrect == false {
            return Color.red.opacity(0.05)
        } else {
            return Color.orange.opacity(0.05)
        }
    }
    
    private var borderColor: Color {
        if feedback.isCorrect == true {
            return Color.green.opacity(0.3)
        } else if feedback.isCorrect == false {
            return Color.red.opacity(0.3)
        } else {
            return Color.orange.opacity(0.3)
        }
    }
}

// MARK: - Simple Camera View (reuse existing)
struct SimpleCameraView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    let onImageCaptured: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: SimpleCameraView
        
        init(_ parent: SimpleCameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Simple Photo Picker View
struct SimplePhotoPickerView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    let onImageSelected: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        picker.mediaTypes = ["public.image"]
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: SimplePhotoPickerView
        
        init(_ parent: SimplePhotoPickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.onImageSelected(image)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Multiple Upload Source Support
extension SolutionFeedbackViewModel {
    
    /// Submit solution from photo library (uses existing submitSolution)
    func submitSolutionFromPhotos(_ image: UIImage) async {
        await submitSolution(image)
    }
    
    /// Submit solution from file picker with security-scoped resource handling
    func submitSolutionFromFile(_ url: URL) async {
        isLoading = true
        
        // Handle security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            await MainActor.run {
                errorMessage = "Cannot access the selected file. Please try again."
                showingError = true
                isLoading = false
            }
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
            isLoading = false
        }
        
        do {
            let image = try await loadImageFromFile(url: url)
            await submitSolution(image) // Use existing method
        } catch {
            await MainActor.run {
                errorMessage = "Could not load image: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
    
    // MARK: - Private File Loading Helpers
    
    private func loadImageFromFile(url: URL) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Check if it's a PDF
                    if url.pathExtension.lowercased() == "pdf" {
                        if let image = self.convertPDFToImage(url: url) {
                            continuation.resume(returning: image)
                        } else {
                            throw SolutionFeedbackError.imageProcessingFailed
                        }
                    } else {
                        // Handle regular image files
                        let data = try Data(contentsOf: url)
                        
                        if let image = UIImage(data: data) {
                            continuation.resume(returning: image)
                        } else {
                            throw SolutionFeedbackError.imageProcessingFailed
                        }
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func convertPDFToImage(url: URL) -> UIImage? {
        guard let document = CGPDFDocument(url as CFURL),
              let page = document.page(at: 1) else {
            return nil
        }
        
        let pageRect = page.getBoxRect(.mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        
        let image = renderer.image { context in
            UIColor.white.set()
            context.fill(pageRect)
            
            context.cgContext.translateBy(x: 0, y: pageRect.size.height)
            context.cgContext.scaleBy(x: 1.0, y: -1.0)
            context.cgContext.drawPDFPage(page)
        }
        
        return image
    }
}
