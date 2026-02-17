//
//  FullWorksheetFeedbackButtonWithHomework.swift
//  PeaTutorApp
//
//  Sprint 5 Phase 2: Enhanced feedback button with homework context
//

import SwiftUI
import Amplify

/// Enhanced FullWorksheetFeedbackButton that links submissions to homework
struct FullWorksheetFeedbackButtonWithHomework: View {
    let worksheetId: String
    let questions: [ExtractedQuestion]
    let homework: Homework
    let onSubmission: () -> Void
    
    @StateObject private var viewModel: FullWorksheetFeedbackWithHomeworkViewModel
    @State private var showingSourcePicker = false
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var showingFilePicker = false
    
    init(worksheetId: String, questions: [ExtractedQuestion], homework: Homework, onSubmission: @escaping () -> Void) {
        self.worksheetId = worksheetId
        self.questions = questions
        self.homework = homework
        self.onSubmission = onSubmission
        
        _viewModel = StateObject(wrappedValue: FullWorksheetFeedbackWithHomeworkViewModel(
            worksheetId: worksheetId,
            questions: questions,
            homework: homework,
            onSubmission: onSubmission
        ))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Main submission button
            Button(action: { showingSourcePicker = true }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                    Text(viewModel.isLoading ? "Submitting..." : "Submit Homework")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isLoading ? Color.gray : (isOverdue ? Color.orange : Color.blue))
                .cornerRadius(12)
            }
            .disabled(viewModel.isLoading)
            
            // Late submission warning
            if isOverdue && (homework.allowLateSubmissions ?? false) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("This homework is overdue. Your submission will be marked as late.")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            } else if isOverdue {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("This homework is overdue and late submissions are not allowed.")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Attempt counter
            if viewModel.existingAttempts > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.purple)
                    Text("Attempt \(viewModel.existingAttempts + 1)")
                        .font(.caption)
                        .foregroundColor(.purple)
                    
                    if let maxAttempts = homework.maxAttempts {
                        Text("of \(maxAttempts)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingSourcePicker) {
            UploadSourcePicker(
                onChooseCamera: {
                    showingCamera = true
                },
                onChoosePhotos: {
                    showingPhotoPicker = true
                },
                onChooseFiles: {
                    showingFilePicker = true
                },
                onDismiss: {
                    showingSourcePicker = false
                }
            )
        }
        .sheet(isPresented: $showingCamera) {
            CameraCapture { image in
                showingCamera = false
                Task {
                    await viewModel.submitHomeworkSolution(image)
                }
            }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            SimplePhotoPickerView { image in
                showingPhotoPicker = false
                Task {
                    await viewModel.submitHomeworkSolution(image)
                }
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.image, .pdf],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    Task {
                        await viewModel.submitSolutionFromFile(url)
                    }
                }
            case .failure(let error):
                print("File picker error: \(error)")
            }
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error occurred")
        }
        .alert("Success!", isPresented: $viewModel.showingSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your homework has been submitted successfully!")
        }
    }
    
    private var isOverdue: Bool {
        homework.dueDate.foundationDate < Date()
    }
}

// MARK: - View Model with Homework Context

@MainActor
class FullWorksheetFeedbackWithHomeworkViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var existingAttempts = 0
    @Published var errorMessage: String?
    @Published var showingError = false
    @Published var showingSuccess = false
    
    private let worksheetId: String
    private let questions: [ExtractedQuestion]
    private let homework: Homework
    private let onSubmission: () -> Void
    
    private let awsService = AWSService.shared
    private let homeworkService = HomeworkService.shared
    
    init(worksheetId: String, questions: [ExtractedQuestion], homework: Homework, onSubmission: @escaping () -> Void) {
        self.worksheetId = worksheetId
        self.questions = questions
        self.homework = homework
        self.onSubmission = onSubmission
        
        Task {
            await loadExistingAttempts()
        }
    }
    
    // MARK: - Load Existing Attempts
    
    func loadExistingAttempts() async {
        guard let userId = awsService.currentUserId else { return }
        
        do {
            let solutions = try await Amplify.DataStore.query(
                FullWorksheetSolution.self,
                where: FullWorksheetSolution.keys.homework.eq(homework.id)
                    && FullWorksheetSolution.keys.userId == userId
            )
            
            existingAttempts = solutions.count
        } catch {
            print("⚠️ Failed to load existing attempts: \(error)")
        }
    }
    
    // MARK: - Submit Homework Solution
    
    func submitHomeworkSolution(_ image: UIImage) async {
        // Check if late submissions are allowed
        let isLate = homework.dueDate.foundationDate < Date()
        if isLate && !(homework.allowLateSubmissions ?? false) {
            errorMessage = "Late submissions are not allowed for this homework."
            showingError = true
            return
        }
        
        // Check attempt limits
        if let maxAttempts = homework.maxAttempts, existingAttempts >= maxAttempts {
            errorMessage = "You have reached the maximum number of attempts (\(maxAttempts)) for this homework."
            showingError = true
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        print("📤 Submitting homework solution for homework: \(homework.id)")
        
        do {
            // 1. Optimize image
            guard let imageData = image.jpegData(compressionQuality: 0.85) else {
                throw HomeworkSubmissionError.imageProcessingFailed
            }
            
            // 2. Upload to S3
            let s3Key = try await awsService.uploadSolutionImage(
                imageData,
                worksheetId: worksheetId,
                questionId: "homework-\(homework.id)"
            )
            print("✅ Uploaded to S3: \(s3Key)")
            
            // 3. Get AI feedback
            guard let client = OpenAIClient() else {
                throw HomeworkSubmissionError.openAIClientUnavailable
            }
            
            let aiResult = try await client.analyzeFullWorksheetSolution(
                questions: questions,
                solutionImageData: imageData
            )
            print("✅ AI feedback received")
            
            // 4. Wait for worksheet to sync
            print("⏳ Waiting for worksheet to sync to DataStore...")
            let worksheet = try await waitForWorksheetSync(worksheetId: worksheetId, maxAttempts: 10)
            print("✅ Worksheet synced: \(worksheet.id)")
            
            // 5. Create FullWorksheetSolution with homework context
            guard let userId = awsService.currentUserId else {
                throw HomeworkSubmissionError.userNotAuthenticated
            }
            
            let attemptNumber = existingAttempts + 1
            
            let solution = FullWorksheetSolution(
                id: UUID().uuidString,
                userId: userId,
                s3SolutionImageKey: s3Key,
                overallFeedback: aiResult.overallFeedback,
                overallScore: aiResult.overallScore,
                totalQuestions: questions.count,
                completedQuestions: aiResult.completedQuestions,
                questionsWithIssues: aiResult.questionsWithIssues,
                suggestions: aiResult.suggestions,
                detailedFeedback: try? JSONEncoder().encode(aiResult.detailedFeedback).base64EncodedString(),
                attemptNumber: attemptNumber,
                submittedAt: Temporal.DateTime.now(),
                worksheet: worksheet,
                aiModel: "gpt-4",
                tokensUsed: nil,
                homework: homework, // ✅ Link to homework
                isLate: isLate,     // ✅ Mark if late
                teacherReviewed: false, // ✅ Needs teacher review
                teacherNotes: nil,
                teacherReviewedAt: nil,
                teacherReviewedBy: nil
            )
            
            let saved = try await Amplify.DataStore.save(solution)
            print("✅ Homework submission saved: \(saved.id)")
            
            // ✅ SPRINT 7 ANALYTICS GENERATION - For homework submissions
                   print("📈 Generating analytics for homework submission...")
                   
                   // Get classroom context from homework
                   let classroomId = homework.classroom?.id
                   
                   // Try to get worksheet metadata
                   let allMetadata = try? await Amplify.DataStore.query(WorksheetMetadata.self)
                   let metadata = allMetadata?.filter { $0.worksheet?.id == worksheet.id }.first
                   
                   // Update concept mastery
                   do {
                       try await AnalyticsService.shared.updateConceptMastery(
                           studentId: userId,
                           classroomId: classroomId,
                           feedback: saved,
                           worksheet: worksheet,
                           metadata: metadata
                       )
                       print("✅ Concept mastery updated")
                   } catch {
                       print("⚠️ Failed to update concept mastery: \(error)")
                   }
                   
                   // Analyze errors from detailed feedback
                   if let detailedData = Data(base64Encoded: saved.detailedFeedback ?? "") {
                       do {
                           let decoder = JSONDecoder()
                           decoder.dateDecodingStrategy = .iso8601
                           let detailedFeedback = try decoder.decode([QuestionFeedback].self, from: detailedData)
                           
                           // Map questionId to ExtractedQuestion
                           let questionMap = Dictionary(uniqueKeysWithValues:
                               questions.map { ($0.id, $0) }
                           )
                           
                           // Analyze errors
                           for feedback in detailedFeedback {
                               guard let question = questionMap[feedback.questionId],
                                     let isCorrect = feedback.isCorrect,
                                     !isCorrect else { continue }
                               
                               try? await AnalyticsService.shared.analyzeAndRecordErrors(
                                   studentId: userId,
                                   classroomId: classroomId,
                                   questionId: question.id,
                                   question: question,
                                   studentAnswer: "Student response (see worksheet image)",
                                   feedback: feedback.feedback,
                                   isCorrect: false
                               )
                           }
                           print("✅ Error patterns analyzed")
                       } catch {
                           print("⚠️ Failed to analyze error patterns: \(error)")
                       }
                   }
                   
                   // Trigger summary calculation (non-blocking)
                   Task {
                       do {
                           _ = try await AnalyticsQueryService.shared.fetchStudentSummary(
                               studentId: userId,
                               classroomId: classroomId
                           )
                           print("✅ Analytics summary calculated")
                       } catch {
                           print("⚠️ Failed to calculate analytics summary: \(error)")
                       }
                   }
            
            // 6. Update HomeworkAnalytics
            // Optional: Manually update HomeworkAnalytics if needed
            if let classroom = homework.classroom {
                // Query existing analytics
                let analytics = try await Amplify.DataStore.query(
                    HomeworkAnalytics.self,
                    where: HomeworkAnalytics.keys.homeworkId == homework.id
                )
                
                if let existingAnalytics = analytics.first {
                    // Update counts
                    let updatedAnalytics = HomeworkAnalytics(
                        id: existingAnalytics.id,
                        homeworkId: existingAnalytics.homeworkId,
                        teacherId: existingAnalytics.teacherId,
                        totalStudents: existingAnalytics.totalStudents,
                        submittedCount: existingAnalytics.submittedCount + 1,
                        totalSubmissions: existingAnalytics.totalSubmissions + 1,
                        lateCount: existingAnalytics.lateCount + (isLate ? 1 : 0),
                        averageAttempts: existingAnalytics.averageAttempts,
                        multipleAttemptsCount: existingAnalytics.multipleAttemptsCount,
                        reviewedCount: existingAnalytics.reviewedCount,
                        pendingReviewCount: existingAnalytics.pendingReviewCount + 1,
                        commonMistakes: existingAnalytics.commonMistakes,
                        strugglingStudents: existingAnalytics.strugglingStudents,
                        lastUpdatedAt: Temporal.DateTime.now(),
                        lastCalculatedAt: existingAnalytics.lastCalculatedAt,
                        createdAt: existingAnalytics.createdAt,
                        updatedAt: Temporal.DateTime.now()
                    )
                    
                    try await Amplify.DataStore.save(updatedAnalytics)
                    print("✅ Analytics manually updated")
                }
            }
            
            // 7. Update StudentProgress
            if let classroom = homework.classroom {
                try await homeworkService.updateStudentProgress(
                    studentId: userId,
                    classroom: classroom  // ✅ FIXED: Pass classroom object
                )
                print("✅ Student progress updated")
            }
            
            // 8. Success!
            existingAttempts += 1
            showingSuccess = true
            onSubmission()
            print("🎉 Homework submission complete!")
            
        } catch {
            errorMessage = "Failed to submit homework: \(error.localizedDescription)"
            showingError = true
            print("❌ Submission error: \(error)")
        }
    }
    
    // MARK: - Submit from File
    
    func submitSolutionFromFile(_ url: URL) async {
        guard url.startAccessingSecurityScopedResource() else {
            errorMessage = "Cannot access the selected file. Please try again."
            showingError = true
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        do {
            let image = try await loadImageFromFile(url: url)
            await submitHomeworkSolution(image)
        } catch {
            errorMessage = "Failed to load image from file: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    // MARK: - Helper Methods
    
    private func waitForWorksheetSync(worksheetId: String, maxAttempts: Int) async throws -> Worksheet {
        for attempt in 1...maxAttempts {
            do {
                if let worksheet = try await Amplify.DataStore.query(Worksheet.self, byId: worksheetId) {
                    return worksheet
                }
            } catch {
                print("⚠️ Worksheet sync attempt \(attempt)/\(maxAttempts) failed")
            }
            
            if attempt < maxAttempts {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
        }
        
        throw HomeworkSubmissionError.worksheetNotFound
    }
    
    private func loadImageFromFile(url: URL) async throws -> UIImage {
        let data = try Data(contentsOf: url)
        
        // Check if PDF
        if url.pathExtension.lowercased() == "pdf" {
            // Convert first page of PDF to image
            guard let provider = CGDataProvider(data: data as CFData),
                  let pdfDocument = CGPDFDocument(provider),
                  let pdfPage = pdfDocument.page(at: 1) else {
                throw HomeworkSubmissionError.invalidFileFormat
            }
            
            let pageRect = pdfPage.getBoxRect(.mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
            
            let image = renderer.image { ctx in
                UIColor.white.set()
                ctx.fill(pageRect)
                
                ctx.cgContext.translateBy(x: 0, y: pageRect.size.height)
                ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                ctx.cgContext.drawPDFPage(pdfPage)
            }
            
            return image
        } else {
            // Regular image
            guard let image = UIImage(data: data) else {
                throw HomeworkSubmissionError.invalidFileFormat
            }
            return image
        }
    }
}

// MARK: - Error Types

enum HomeworkSubmissionError: Error, LocalizedError {
    case imageProcessingFailed
    case openAIClientUnavailable
    case worksheetNotFound
    case userNotAuthenticated
    case invalidFileFormat
    case lateSubmissionNotAllowed
    case maxAttemptsReached
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Could not process image"
        case .openAIClientUnavailable:
            return "OpenAI client not available"
        case .worksheetNotFound:
            return "Worksheet not found in database"
        case .userNotAuthenticated:
            return "User not authenticated"
        case .invalidFileFormat:
            return "Invalid file format"
        case .lateSubmissionNotAllowed:
            return "Late submissions are not allowed"
        case .maxAttemptsReached:
            return "Maximum attempts reached"
        }
    }
}

// MARK: - Upload Source Picker (Reusable Component)

struct UploadSourcePicker: View {
    let onChooseCamera: () -> Void
    let onChoosePhotos: () -> Void
    let onChooseFiles: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Choose Upload Method")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                VStack(spacing: 16) {
                    Button(action: {
                        onDismiss()
                        onChooseCamera()
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .frame(width: 40)
                            VStack(alignment: .leading) {
                                Text("Take Photo")
                                    .font(.headline)
                                Text("Use camera to capture your work")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        onDismiss()
                        onChoosePhotos()
                    }) {
                        HStack {
                            Image(systemName: "photo.fill")
                                .font(.title2)
                                .frame(width: 40)
                            VStack(alignment: .leading) {
                                Text("Photo Library")
                                    .font(.headline)
                                Text("Choose from your photos")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        onDismiss()
                        onChooseFiles()
                    }) {
                        HStack {
                            Image(systemName: "doc.fill")
                                .font(.title2)
                                .frame(width: 40)
                            VStack(alignment: .leading) {
                                Text("Browse Files")
                                    .font(.headline)
                                Text("Choose PDF or image file")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarItems(trailing: Button("Cancel") { onDismiss() })
        }
    }
}

// MARK: - Camera Capture (Simplified)

struct CameraCapture: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    @Environment(\.presentationMode) var presentationMode
    
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
        let parent: CameraCapture
        
        init(_ parent: CameraCapture) {
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
