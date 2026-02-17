//
//  HomeworkDetailView.swift
//  PeaTutorApp
//
//  Sprint 5 Phase 2: Student Views Homework
//  Core view for students to view homework details and submit solutions
//

import SwiftUI
import Amplify

struct HomeworkDetailView: View {
    let homework: Homework
    
    @StateObject private var awsService = AWSService.shared
    @StateObject private var homeworkService = HomeworkService.shared
    @State private var worksheet: Worksheet?
    @State private var extractedWorksheet: ExtractedWorksheet?
    @State private var teacherProfile: UserProfile?
    @State private var submissionStatus: HomeworkSubmissionStatus = .notStarted
    @State private var existingSubmissions: [FullWorksheetSolution] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading homework...")
            } else if let error = errorMessage {
                ContentUnavailableView(
                    "Error Loading Homework",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if let extractedWorksheet = extractedWorksheet {
                ScrollView {
                    VStack(spacing: 24) {
                        // Homework Header
                        homeworkHeaderCard
                        
                        // Status Badge
                        statusBadge
                        
                        // Worksheet Questions Section
                        questionsSection(extractedWorksheet: extractedWorksheet)
                        
                        // Previous Submissions (if any)
                        if !existingSubmissions.isEmpty {
                            previousSubmissionsSection
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(homework.title)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown error occurred")
        }
        .task {
            await loadHomeworkData()
        }
    }
    
    // MARK: - Homework Header Card
    
    private var homeworkHeaderCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Text(homework.title)
                .font(.title2.bold())
            
            // Description
            if let description = homework.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Metadata Grid
            VStack(spacing: 12) {
                // Due Date
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Due Date")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatDueDate(homework.dueDate))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    // Countdown (if close to due date)
                    if let countdown = dueDateCountdown {
                        Text(countdown)
                            .font(.caption)
                            .foregroundColor(isOverdue ? .red : .orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(isOverdue ? Color.red.opacity(0.1) : Color.orange.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
                
                // Assigned Date
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Assigned")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatDate(homework.assignedDate))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                }
                
                // Teacher
                if let teacher = teacherProfile {
                    HStack {
                        Image(systemName: "person.circle")
                            .foregroundColor(.purple)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Teacher")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(teacher.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                    }
                }
                
                // Total Points
                if let totalPoints = homework.totalPoints {
                    HStack {
                        Image(systemName: "star.circle")
                            .foregroundColor(.yellow)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Total Points")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(totalPoints) points")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                    }
                }
            }
            
            // Instructions (if provided)
            if let instructions = homework.instructions, !instructions.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "list.bullet.clipboard")
                            .foregroundColor(.blue)
                        Text("Instructions")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    Text(instructions)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            // Learning Objectives (if provided)
            if let objectives = homework.learningObjectives, !objectives.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(.green)
                        Text("Learning Objectives")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    Text(objectives)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Status Badge
    
    private var statusBadge: some View {
        HStack(spacing: 16) {
            HStack {
                Image(systemName: submissionStatus.icon)
                    .foregroundColor(submissionStatus.color)
                Text(submissionStatus.displayText)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(submissionStatus.color.opacity(0.15))
            .cornerRadius(10)
            
            if !existingSubmissions.isEmpty {
                Text("\(existingSubmissions.count) attempt\(existingSubmissions.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Questions Section
    
    private func questionsSection(extractedWorksheet: ExtractedWorksheet) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.blue)
                Text("Worksheet Questions")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(extractedWorksheet.questions.count) questions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Embed QuestionContainerView with enhanced feedback button
            if let worksheetId = worksheet?.id {
                QuestionContainerWithHomeworkContext(
                    result: extractedWorksheet,
                    worksheetId: worksheetId,
                    homework: homework,
                    onSubmission: {
                        // Reload submissions after new submission
                        Task {
                            await loadExistingSubmissions()
                            await updateSubmissionStatus()
                        }
                    }
                )
                .frame(height: 600) // Fixed height for embedded view
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - Previous Submissions Section
    
    private var previousSubmissionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.purple)
                Text("Previous Submissions")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            ForEach(existingSubmissions.sorted(by: { $0.submittedAt > $1.submittedAt }), id: \.id) { submission in
                SubmissionCard(submission: submission, homework: homework)
            }
        }
        .padding()
        .background(Color.purple.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - Data Loading
    
    private func loadHomeworkData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load worksheet
            guard let homeworkWorksheet = homework.worksheet else {
                throw HomeworkViewError.worksheetNotFound
            }
            
            worksheet = homeworkWorksheet
            
            // Parse extraction result
            if let extractionResultJSON = homeworkWorksheet.extractionResult {
                extractedWorksheet = try DataStoreService.shared.parseExtractionResult(extractionResultJSON)
            }
            
            // Load teacher profile
            let profiles = try await Amplify.DataStore.query(
                UserProfile.self,
                where: UserProfile.keys.id == homework.teacherId
            )
            teacherProfile = profiles.first
            
            // Load existing submissions
            await loadExistingSubmissions()
            
            // Update submission status
            await updateSubmissionStatus()
            
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func loadExistingSubmissions() async {
        guard let userId = awsService.currentUserId,
              let worksheetId = worksheet?.id else { return }
        
        do {
            // Query FullWorksheetSolutions for this homework
            let solutions = try await Amplify.DataStore.query(
                FullWorksheetSolution.self,
                where: FullWorksheetSolution.keys.homework.eq(homework.id)
                    && FullWorksheetSolution.keys.userId == userId
            )
            
            await MainActor.run {
                existingSubmissions = solutions
            }
            
        } catch {
            print("⚠️ Failed to load existing submissions: \(error)")
        }
    }
    
    private func updateSubmissionStatus() async {
        await MainActor.run {
            if !existingSubmissions.isEmpty {
                submissionStatus = .submitted
            } else if isOverdue {
                submissionStatus = .overdue
            } else {
                submissionStatus = .notStarted
            }
        }
    }
    
    // MARK: - Date Formatting
    
    private func formatDueDate(_ date: Temporal.DateTime) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date.foundationDate)
    }
    
    private func formatDate(_ date: Temporal.DateTime) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date.foundationDate, relativeTo: Date())
    }
    
    private var dueDateCountdown: String? {
        let now = Date()
        let dueDate = homework.dueDate.foundationDate
        let timeInterval = dueDate.timeIntervalSince(now)
        
        // Only show countdown if within 7 days
        guard timeInterval > 0 && timeInterval < 7 * 24 * 60 * 60 else {
            return nil
        }
        
        let hours = Int(timeInterval / 3600)
        let days = hours / 24
        
        if days > 0 {
            return "Due in \(days) day\(days == 1 ? "" : "s")"
        } else {
            return "Due in \(hours) hour\(hours == 1 ? "" : "s")"
        }
    }
    
    private var isOverdue: Bool {
        homework.dueDate.foundationDate < Date()
    }
}

// MARK: - Homework Submission Status

enum HomeworkSubmissionStatus {
    case notStarted
    case submitted
    case overdue
    
    var displayText: String {
        switch self {
        case .notStarted: return "Not Started"
        case .submitted: return "Submitted"
        case .overdue: return "Overdue"
        }
    }
    
    var icon: String {
        switch self {
        case .notStarted: return "circle"
        case .submitted: return "checkmark.circle.fill"
        case .overdue: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .notStarted: return .gray
        case .submitted: return .green
        case .overdue: return .red
        }
    }
}

// MARK: - Submission Card

private struct SubmissionCard: View {
    let submission: FullWorksheetSolution
    let homework: Homework
    
    var body: some View {
        HStack(spacing: 12) {
            // Attempt Number
            VStack {
                Text("#\(submission.attemptNumber)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                
                Text("Attempt")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60)
            
            Divider()
            
            // Submission Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Score: \(submission.overallScore)/\(submission.totalQuestions)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if submission.isLate ?? false {
                        Text("LATE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                Text(formatDate(submission.submittedAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if submission.teacherReviewed ?? false {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text("Reviewed by teacher")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Spacer()
            
            // View Button
            NavigationLink {
                EnhancedStudentSubmissionDetailView(submission: submission, homework: homework)
            } label: {
                Image(systemName: "arrow.right.circle")
                    .font(.title3)
                    .foregroundColor(.purple)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
    
    private func formatDate(_ date: Temporal.DateTime) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date.foundationDate, relativeTo: Date())
    }
}

// MARK: - Question Container with Homework Context

/// Wrapper around QuestionContainerView that passes homework context to the feedback button
struct QuestionContainerWithHomeworkContext: View {
    let result: ExtractedWorksheet
    let worksheetId: String
    let homework: Homework
    let onSubmission: () -> Void
    
    @State private var currentQuestionIndex = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            progressBar
            
            // Question navigation
            TabView(selection: $currentQuestionIndex) {
                ForEach(result.questions.indices, id: \.self) { index in
                    QuestionDetailView(
                        question: result.questions[index],
                        questionNumber: index + 1,
                        worksheetId: worksheetId
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Bottom toolbar with homework-aware feedback button
            bottomToolbar
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)
                
                Rectangle()
                    .fill(Color.blue)
                    .frame(
                        width: geometry.size.width * CGFloat(currentQuestionIndex + 1) / CGFloat(result.questions.count),
                        height: 4
                    )
                    .animation(.easeInOut, value: currentQuestionIndex)
            }
        }
        .frame(height: 4)
    }
    
    // MARK: - Bottom Toolbar
    
    private var bottomToolbar: some View {
        VStack(spacing: 12) {
            // Homework-aware full worksheet feedback button
            FullWorksheetFeedbackButtonWithHomework(
                worksheetId: worksheetId,
                questions: result.questions,
                homework: homework,
                onSubmission: onSubmission
            )
            .padding(.horizontal)
            
            Divider()
            
            // Navigation controls (simplified version)
            HStack(spacing: 20) {
                Button(action: { withAnimation { previousQuestion() } }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Previous")
                    }
                    .font(.subheadline)
                    .foregroundColor(currentQuestionIndex > 0 ? .blue : .gray)
                }
                .disabled(currentQuestionIndex == 0)
                
                Spacer()
                
                Text("Question \(currentQuestionIndex + 1)/\(result.questions.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: { withAnimation { nextQuestion() } }) {
                    HStack {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline)
                    .foregroundColor(currentQuestionIndex < result.questions.count - 1 ? .blue : .gray)
                }
                .disabled(currentQuestionIndex == result.questions.count - 1)
            }
            .padding(.horizontal)
        }
        .background(Color(.systemBackground))
    }
    
    private func previousQuestion() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
        }
    }
    
    private func nextQuestion() {
        if currentQuestionIndex < result.questions.count - 1 {
            currentQuestionIndex += 1
        }
    }
}

// MARK: - Error Types

enum HomeworkViewError: Error, LocalizedError {
    case worksheetNotFound
    case extractionResultMissing
    
    var errorDescription: String? {
        switch self {
        case .worksheetNotFound:
            return "Worksheet not found for this homework"
        case .extractionResultMissing:
            return "Worksheet questions are not available"
        }
    }
}
