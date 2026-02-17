//
//  EnhancedTeacherSubmissionDetailView.swift
//  PeaTutorApp
//
//  Sprint 7: Enhanced version with complete AI feedback display
//

import SwiftUI
import Amplify

struct TeacherSubmissionDetailView: View {
    let submission: FullWorksheetSolution
    let homework: Homework
    let studentProfile: UserProfile?
    
    @StateObject private var homeworkService = HomeworkService.shared
    @StateObject private var awsService = AWSService.shared
    
    @State private var teacherNotes: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    @State private var solutionImage: UIImage?
    @State private var isLoadingImage = false
    @State private var detailedFeedback: [QuestionFeedback] = []
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Student Header
                studentHeader
                
                // Submission Info
                submissionInfoCard
                
                // Solution Image
                solutionImageSection
                
                // AI Feedback (Enhanced!)
                enhancedAIFeedbackSection
                
                // Teacher Notes Section
                teacherNotesSection
                
                // Mark as Reviewed Button
                if submission.teacherReviewed != true {
                    markAsReviewedButton
                }
            }
            .padding()
        }
        .navigationTitle("Review Submission")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Submission marked as reviewed successfully")
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .task {
            teacherNotes = submission.teacherNotes ?? ""
            parseDetailedFeedback()
            await loadSolutionImage()
        }
    }
    
    // MARK: - Student Header
    private var studentHeader: some View {
        HStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Text(studentProfile?.initials ?? "?")
                        .font(.title2.bold())
                        .foregroundColor(.blue)
                )
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(studentProfile?.displayName ?? "Unknown Student")
                    .font(.title3.bold())
                
                if let email = studentProfile?.email {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 8) {
                    if submission.teacherReviewed == true {
                        Label("Reviewed", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Label("Pending Review", systemImage: "circle")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Submission Info
    private var submissionInfoCard: some View {
        VStack(spacing: 16) {
            // Score
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(submission.overallScore)/\(submission.totalQuestions)")
                        .font(.title.bold())
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Percentage")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(percentageString)
                        .font(.title.bold())
                        .foregroundColor(percentageColor)
                }
            }
            
            Divider()
            
            // Details
            VStack(spacing: 12) {
                InfoRow2(icon: "arrow.triangle.2.circlepath", label: "Attempt", value: "\(submission.attemptNumber)")
                InfoRow2(icon: "calendar", label: "Submitted", value: formatDate(submission.submittedAt))
                
                if submission.isLate == true {
                    InfoRow2(icon: "clock.badge.exclamationmark", label: "Status", value: "Late Submission")
                        .foregroundColor(.orange)
                }
                
                if let reviewedAt = submission.teacherReviewedAt {
                    InfoRow2(icon: "checkmark.circle", label: "Reviewed", value: formatDate(reviewedAt))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Solution Image Section
    private var solutionImageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Student's Solution")
                .font(.headline)
            
            if isLoadingImage {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else if let image = solutionImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
            } else {
                ContentUnavailableView(
                    "Image not available",
                    systemImage: "photo",
                    description: Text("Unable to load solution image")
                )
                .frame(height: 300)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Enhanced AI Feedback Section
    private var enhancedAIFeedbackSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("AI Feedback Analysis", systemImage: "brain.head.profile")
                .font(.headline)
                .foregroundColor(.purple)
            
            VStack(spacing: 16) {
                // Overall Assessment Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.purple)
                        Text("Overall Assessment")
                            .font(.subheadline.bold())
                    }
                    Text(submission.overallFeedback)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.purple.opacity(0.05))
                .cornerRadius(12)
                
                // Completed Questions
                if let completed = submission.completedQuestions, !completed.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Completed Questions")
                                .font(.subheadline.bold())
                        }
                        Text(completed.compactMap { $0 }.joined(separator: ", "))
                            .font(.body)
                            .foregroundColor(.green)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.green.opacity(0.05))
                    .cornerRadius(12)
                }
                
                // Questions with Issues
                if let issues = submission.questionsWithIssues, !issues.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Questions Needing Work")
                                .font(.subheadline.bold())
                        }
                        Text(issues.compactMap { $0 }.joined(separator: ", "))
                            .font(.body)
                            .foregroundColor(.orange)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.05))
                    .cornerRadius(12)
                }
                
                // Suggestions
                if let suggestions = submission.suggestions, !suggestions.isEmpty {
                    let nonNilSuggestions = suggestions.compactMap { $0 }
                    if !nonNilSuggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                Text("AI Suggestions")
                                    .font(.subheadline.bold())
                            }
                            
                            ForEach(Array(nonNilSuggestions.enumerated()), id: \.offset) { _, suggestion in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                    Text(suggestion)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.yellow.opacity(0.05))
                        .cornerRadius(12)
                    }
                }
                
                // Question-by-Question Detailed Feedback
                if !detailedFeedback.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .foregroundColor(.blue)
                            Text("Question-by-Question Feedback")
                                .font(.subheadline.bold())
                        }
                        
                        VStack(spacing: 12) {
                            ForEach(Array(detailedFeedback.enumerated()), id: \.offset) { _, feedback in
                                DetailedQuestionFeedbackRow(feedback: feedback)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Teacher Notes Section
    private var teacherNotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Teacher Notes", systemImage: "pencil")
                .font(.headline)
            
            ZStack(alignment: .topLeading) {
                if teacherNotes.isEmpty {
                    Text("Add your comments and feedback for the student...")
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                }
                
                TextEditor(text: $teacherNotes)
                    .frame(minHeight: 120)
                    .padding(4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .opacity(teacherNotes.isEmpty ? 0.5 : 1)
            }
            
            if submission.teacherReviewed == true {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                    Text("Notes saved and visible to student")
                        .font(.caption)
                }
                .foregroundColor(.green)
            }
        }
        .disabled(submission.teacherReviewed == true)
    }
    
    // MARK: - Mark as Reviewed Button
    private var markAsReviewedButton: some View {
        Button(action: {
            Task {
                await markAsReviewed()
            }
        }) {
            if isSubmitting {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            } else {
                Label("Mark as Reviewed", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
        }
        .background(Color.green)
        .cornerRadius(12)
        .disabled(isSubmitting)
    }
    
    // MARK: - Helper Properties
    private var percentageString: String {
        let percentage = (Double(submission.overallScore) / Double(submission.totalQuestions)) * 100
        return String(format: "%.0f%%", percentage)
    }
    
    private var percentageColor: Color {
        let percentage = (Double(submission.overallScore) / Double(submission.totalQuestions)) * 100
        if percentage >= 80 { return .green }
        if percentage >= 60 { return .orange }
        return .red
    }
    
    // MARK: - Helper Methods
    private func formatDate(_ date: Temporal.DateTime) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date.foundationDate)
    }
    
    private func parseDetailedFeedback() {
        guard let detailedJSON = submission.detailedFeedback,
              !detailedJSON.isEmpty else { return }
        
        // Try parsing as base64-encoded JSON first
        if let jsonData = Data(base64Encoded: detailedJSON) {
            if let decoded = try? JSONDecoder().decode([QuestionFeedback].self, from: jsonData) {
                detailedFeedback = decoded
                return
            }
        }
        
        // Try parsing as direct JSON string
        if let jsonData = detailedJSON.data(using: .utf8) {
            if let decoded = try? JSONDecoder().decode([QuestionFeedback].self, from: jsonData) {
                detailedFeedback = decoded
                return
            }
        }
        
        print("⚠️ Could not parse detailed feedback JSON")
    }
    
    private func loadSolutionImage() async {
        isLoadingImage = true
        
        do {
            // Download from S3
            let imageData = try await AWSService.shared.downloadFile(key: submission.s3SolutionImageKey)
            
            await MainActor.run {
                self.solutionImage = UIImage(data: imageData)
            }
        } catch {
            print("Error loading image: \(error.localizedDescription)")
        }
        
        isLoadingImage = false
    }
    
    private func markAsReviewed() async {
        isSubmitting = true
        
        do {
            // Create updated submission with teacher review data
            let updated = FullWorksheetSolution(
                id: submission.id,
                userId: submission.userId,
                s3SolutionImageKey: submission.s3SolutionImageKey,
                overallFeedback: submission.overallFeedback,
                overallScore: submission.overallScore,
                totalQuestions: submission.totalQuestions,
                completedQuestions: submission.completedQuestions,
                questionsWithIssues: submission.questionsWithIssues,
                suggestions: submission.suggestions,
                detailedFeedback: submission.detailedFeedback,
                attemptNumber: submission.attemptNumber,
                submittedAt: submission.submittedAt,
                worksheet: submission.worksheet,
                aiModel: submission.aiModel,
                tokensUsed: submission.tokensUsed,
                homework: submission.homework,
                isLate: submission.isLate,
                teacherReviewed: true,
                teacherNotes: teacherNotes.isEmpty ? nil : teacherNotes,
                teacherReviewedAt: Temporal.DateTime.now(),
                teacherReviewedBy: awsService.currentUserId
            )
            
            // Save updated submission
            try await Amplify.DataStore.save(updated)
            
            // Update analytics
            try await homeworkService.updateAnalytics(for: homework.id)
            
            await MainActor.run {
                showSuccessAlert = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSubmitting = false
    }
}
