//
//  FullWorksheetFeedback.swift
//  PeaTutorApp
//
//  Sub-Sprint 3.4: Enhanced with DataStore sync and history
//

import SwiftUI
import UIKit
import Amplify

// MARK: - Full Worksheet Feedback Model (Local)
struct FullWorksheetFeedback: Identifiable {
    let id = UUID()
    let solutionImage: Data
    let overallFeedback: String
    let overallScore: Int
    let totalQuestions: Int
    let completedQuestions: [String]
    let questionsWithIssues: [String]
    let suggestions: [String]
    let detailedFeedback: [QuestionFeedback]
    let timestamp: Date
    let attemptNumber: Int
    
    // DataStore ID
    var datastoreId: String?
    var isSynced: Bool { datastoreId != nil }
    
    init(
        solutionImage: Data,
        overallFeedback: String,
        overallScore: Int,
        totalQuestions: Int,
        completedQuestions: [String],
        questionsWithIssues: [String],
        suggestions: [String],
        detailedFeedback: [QuestionFeedback],
        timestamp: Date = Date(),
        attemptNumber: Int = 1,
        datastoreId: String? = nil
    ) {
        self.solutionImage = solutionImage
        self.overallFeedback = overallFeedback
        self.overallScore = overallScore
        self.totalQuestions = totalQuestions
        self.completedQuestions = completedQuestions
        self.questionsWithIssues = questionsWithIssues
        self.suggestions = suggestions
        self.detailedFeedback = detailedFeedback
        self.timestamp = timestamp
        self.attemptNumber = attemptNumber
        self.datastoreId = datastoreId
    }
}

// MARK: - Full Worksheet Feedback View Model
@MainActor
class FullWorksheetFeedbackViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showingError = false
    @Published var currentFeedback: FullWorksheetFeedback?
    @Published var feedbackHistory: [FullWorksheetFeedback] = []
    @Published var isSyncing = false
    
    let worksheetId: String
    let questions: [ExtractedQuestion]
    
    init(worksheetId: String, questions: [ExtractedQuestion]) {
        self.worksheetId = worksheetId
        self.questions = questions
    }
    
    // MARK: - Load History
    
    func loadFeedbackHistory() async {
        print("📥 Loading full worksheet feedback history")
        print("🔍 Looking for worksheet ID: \(worksheetId)")
        
        do {
            // Fetch worksheet from DataStore
            guard let worksheet = try await DataStoreService.shared.fetchWorksheet(id: worksheetId) else {
                print("❌ Worksheet not found in DataStore!")
                print("🔍 Searched for ID: \(worksheetId)")
                return
            }
            print("✅ Found worksheet: \(worksheet.title ?? "Untitled")")
            print("🔍 Worksheet DataStore ID: \(worksheet.id)")
            
            let datastoreFeedback = try await DataStoreService.shared.fetchFullWorksheetSolutions(
                for: worksheet
            )
            print("🔍 Found \(datastoreFeedback.count) feedback items in DataStore")
            
            var history: [FullWorksheetFeedback] = []
            
            for (index, feedback) in datastoreFeedback.enumerated() {
                print("🔍 Processing feedback \(index + 1)/\(datastoreFeedback.count)")
                print("   - Feedback ID: \(feedback.id)")
                print("   - S3 Key: \(feedback.s3SolutionImageKey)")
                print("   - Score: \(feedback.overallScore)/\(feedback.totalQuestions)")
                
                // Download solution image
                if let imageData = try? await AWSService.shared.downloadFile(
                    key: feedback.s3SolutionImageKey
                ) {
                    print("   ✅ Downloaded image: \(imageData.count) bytes")
                    
                    // Parse detailed feedback JSON
                    var detailedFeedback: [QuestionFeedback] = []
                    if let detailedJSON = feedback.detailedFeedback,
                       let jsonData = detailedJSON.data(using: .utf8) {
                        detailedFeedback = (try? JSONDecoder().decode([QuestionFeedback].self, from: jsonData)) ?? []
                    }
                    
                    let localFeedback = FullWorksheetFeedback(
                        solutionImage: imageData,
                        overallFeedback: feedback.overallFeedback,
                        overallScore: feedback.overallScore,
                        totalQuestions: feedback.totalQuestions,
                        completedQuestions: feedback.completedQuestions?.compactMap { $0 } ?? [],
                        questionsWithIssues: feedback.questionsWithIssues?.compactMap { $0 } ?? [],
                        suggestions: feedback.suggestions?.compactMap { $0 } ?? [],
                        detailedFeedback: detailedFeedback,
                        timestamp: feedback.submittedAt.foundationDate,
                        attemptNumber: feedback.attemptNumber,
                        datastoreId: feedback.id
                    )
                    history.append(localFeedback)
                    print("   ✅ Added to history")
                } else {
                    print("   ❌ Failed to download image from S3")
                }
            }
            
            await MainActor.run {
                self.feedbackHistory = history.sorted { $0.timestamp > $1.timestamp }
                self.currentFeedback = history.first
                print("✅ Loaded \(history.count) worksheet feedback(s)")
                print("🔍 Current feedback set: \(self.currentFeedback != nil)")
                if let current = self.currentFeedback {
                    print("🔍 Current feedback score: \(current.overallScore)/\(current.totalQuestions)")
                }
            }
            
        } catch {
            print("❌ Failed to load feedback history: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Submit Solution
    
    func submitFullWorksheetSolution(_ image: UIImage) async {
        isLoading = true
        isSyncing = true
        defer { isLoading = false; isSyncing = false }
        
        print("📤 Submitting full worksheet solution")
        
        do {
            // 1. Optimize image
            guard let imageData = image.jpegData(compressionQuality: 0.85) else {
                throw WorksheetFeedbackError.imageProcessingFailed
            }
            
            // 2. Upload to S3
            let s3Key = try await AWSService.shared.uploadSolutionImage(
                imageData,
                worksheetId: worksheetId,
                questionId: "full-worksheet"
            )
            print("✅ Uploaded to S3: \(s3Key)")
            
            // 3. Get AI feedback
            guard let client = OpenAIClient() else {
                throw WorksheetFeedbackError.openAIClientUnavailable
            }
            
            let aiResult = try await client.analyzeFullWorksheetSolution(
                questions: questions,
                solutionImageData: imageData
            )
            print("✅ AI feedback received")
            
            // 4. ✅ NEW: Wait for worksheet to be saved to DataStore
                    print("⏳ Waiting for worksheet to sync to DataStore...")
                    let worksheet = try await waitForWorksheetSync(worksheetId: worksheetId, maxAttempts: 10)
                    print("✅ Worksheet synced: \(worksheet.id)")

            
            // 5. Create local feedback first
            let localFeedback = FullWorksheetFeedback(
                solutionImage: imageData,
                overallFeedback: aiResult.overallFeedback,
                overallScore: aiResult.overallScore,
                totalQuestions: questions.count,
                completedQuestions: aiResult.completedQuestions,
                questionsWithIssues: aiResult.questionsWithIssues,
                suggestions: aiResult.suggestions,
                detailedFeedback: aiResult.detailedFeedback,
                attemptNumber: feedbackHistory.count + 1
            )
            
            // 6. Save to DataStore
            let datastoreFeedback = try await DataStoreService.shared.saveFullWorksheetSolution(
                localFeedback: localFeedback,
                s3ImageKey: s3Key,
                worksheet: worksheet
            )
            print("✅ Saved to DataStore: \(datastoreFeedback.id)")
            
            // 7. Update local feedback with DataStore ID
            var syncedFeedback = localFeedback
            syncedFeedback.datastoreId = datastoreFeedback.id
            
            await MainActor.run {
                currentFeedback = syncedFeedback
                feedbackHistory.insert(syncedFeedback, at: 0)
                print("🎉 Full worksheet solution submitted!")
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to submit solution: \(error.localizedDescription)"
                showingError = true
                print("❌ Submission error: \(error)")
            }
        }
    }
}

// MARK: - Error Types
enum WorksheetFeedbackError: Error, LocalizedError {
    case imageProcessingFailed
    case openAIClientUnavailable
    case uploadFailed
    case worksheetNotFound
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Could not process image"
        case .openAIClientUnavailable:
            return "OpenAI client not available"
        case .uploadFailed:
            return "Failed to upload to cloud"
        case .worksheetNotFound:
            return "Worksheet not found in database"
        case .saveFailed:
            return "Failed to save feedback"
        }
    }
}

// MARK: - Enhanced Full Worksheet Feedback Button with Multiple Upload Sources
struct FullWorksheetFeedbackButton: View {
    let worksheetId: String
    let questions: [ExtractedQuestion]
    
    @StateObject private var viewModel: FullWorksheetFeedbackViewModel
    @State private var showingSourcePicker = false
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var showingFilePicker = false
    @State private var showingHistory = false
    
    init(worksheetId: String, questions: [ExtractedQuestion]) {
        self.worksheetId = worksheetId
        self.questions = questions
        
        _viewModel = StateObject(wrappedValue: FullWorksheetFeedbackViewModel(
            worksheetId: worksheetId,
            questions: questions
        ))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Main button row
            HStack(spacing: 12) {
                // Upload button
                Button(action: { showingSourcePicker = true }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "photo.badge.plus")
                        }
                        Text(viewModel.isLoading ? "Analyzing..." : "Full Worksheet Feedback")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isLoading ? Color.gray : Color.blue)
                    .cornerRadius(12)
                }
                .disabled(viewModel.isLoading)
                
                // History button
                if !viewModel.feedbackHistory.isEmpty {
                    Button(action: { showingHistory = true }) {
                        VStack(spacing: 4) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.title3)
                            Text("\(viewModel.feedbackHistory.count)")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.blue)
                        .frame(width: 60)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
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
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Current feedback display
            if let feedback = viewModel.currentFeedback {
                FullWorksheetFeedbackCard(feedback: feedback)
            }
        }
        // Source selection dialog
        .confirmationDialog(
            "Upload Worksheet Solution",
            isPresented: $showingSourcePicker,
            titleVisibility: .visible
        ) {
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
            Text("Choose how to upload your complete work")
        }
        // Camera capture
        .fullScreenCover(isPresented: $showingCamera) {
            SimpleCameraView { capturedImage in
                Task {
                    await viewModel.submitFullWorksheetSolution(capturedImage)
                }
            }
        }
        // Photo library picker
        .sheet(isPresented: $showingPhotoPicker) {
            SimplePhotoPickerView { selectedImage in
                Task {
                    await viewModel.submitSolutionFromPhotos(selectedImage)
                }
            }
        }
        // File importer
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.image, .jpeg, .png, .heic, .pdf],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result: result)
        }
        // History view
        .sheet(isPresented: $showingHistory) {
            FullWorksheetHistoryView(viewModel: viewModel)
        }
        // Error alert
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        // Load history on appear
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
                viewModel.errorMessage = "Camera access is required to capture your worksheet"
                viewModel.showingError = true
            }
        }
    }
    
    private func requestPhotosAndShow() {
        ImagePermissionHelper.requestPhotoLibraryPermission { granted in
            if granted {
                showingPhotoPicker = true
            } else {
                viewModel.errorMessage = "Photo library access is required to select your worksheet."
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

// MARK: - Full Worksheet Feedback Card
struct FullWorksheetFeedbackCard: View {
    let feedback: FullWorksheetFeedback
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Overall Score:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("\(feedback.overallScore)/\(feedback.totalQuestions)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(scoreColor)
                    }
                    
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
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            
            // Overall feedback
            Text(feedback.overallFeedback)
                .font(.subheadline)
                .lineLimit(isExpanded ? nil : 3)
            
            // Expanded details
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // Completed questions
                    if !feedback.completedQuestions.isEmpty {
                        statsRow(
                            icon: "checkmark.circle.fill",
                            color: .green,
                            title: "Completed",
                            items: feedback.completedQuestions
                        )
                    }
                    
                    // Issues
                    if !feedback.questionsWithIssues.isEmpty {
                        statsRow(
                            icon: "exclamationmark.triangle.fill",
                            color: .orange,
                            title: "Needs Work",
                            items: feedback.questionsWithIssues
                        )
                    }
                    
                    // Suggestions
                    if !feedback.suggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.orange)
                                Text("Suggestions")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            
                            ForEach(feedback.suggestions, id: \.self) { suggestion in
                                Text("• \(suggestion)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private func statsRow(icon: String, color: Color, title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            Text(items.joined(separator: ", "))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var scoreColor: Color {
        let percentage = Double(feedback.overallScore) / Double(feedback.totalQuestions)
        if percentage >= 0.7 { return .green }
        else if percentage >= 0.4 { return .orange }
        else { return .red }
    }
}

// MARK: - Feedback Options Sheet (reuse existing)
struct FeedbackOptionsSheet: View {
    let questionsCount: Int
    let onChooseFullWorksheet: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("How would you like feedback?")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                }
                
                Button(action: onChooseFullWorksheet) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "doc.fill")
                                .font(.title2)
                            Text("Full Worksheet Review")
                                .font(.headline)
                            Spacer()
                        }
                        Text("Get comprehensive feedback across all \(questionsCount) questions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.primary)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Choose Feedback Type")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") { onDismiss() })
        }
    }
}
// MARK: - Multiple Upload Source Support
extension FullWorksheetFeedbackViewModel {
    
    /// Submit solution from photo library (uses existing submitFullWorksheetSolution)
    func submitSolutionFromPhotos(_ image: UIImage) async {
        await submitFullWorksheetSolution(image)
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
            await submitFullWorksheetSolution(image) // Use your existing method!
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
                            throw WorksheetFeedbackError.imageProcessingFailed
                        }
                    } else {
                        // Handle regular image files
                        let data = try Data(contentsOf: url)
                        
                        if let image = UIImage(data: data) {
                            continuation.resume(returning: image)
                        } else {
                            throw WorksheetFeedbackError.imageProcessingFailed
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

extension FullWorksheetFeedbackViewModel {
    /// Wait for worksheet to appear in DataStore (with retry logic)
    private func waitForWorksheetSync(
        worksheetId: String,
        maxAttempts: Int = 10,
        delaySeconds: Double = 0.5
    ) async throws -> Worksheet {
        for attempt in 1...maxAttempts {
            if let worksheet = try await DataStoreService.shared.fetchWorksheet(id: worksheetId) {
                print("✅ Found worksheet on attempt \(attempt)")
                return worksheet
            }
            
            if attempt < maxAttempts {
                print("⏳ Worksheet not found, attempt \(attempt)/\(maxAttempts), retrying...")
                try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
            }
        }
        
        throw WorksheetFeedbackError.worksheetNotFound
    }
}
