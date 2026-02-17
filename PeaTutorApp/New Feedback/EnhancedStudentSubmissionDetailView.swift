//
//  EnhancedStudentSubmissionDetailView.swift
//  PeaTutorApp
//
//  Sprint 7: Enhanced submission view for students with full AI feedback
//

import SwiftUI
import Amplify

struct EnhancedStudentSubmissionDetailView: View {
    let submission: FullWorksheetSolution
    let homework: Homework
    
    @State private var solutionImage: UIImage?
    @State private var isLoadingImage = false
    @State private var detailedFeedback: [QuestionFeedback] = []
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Card
                headerCard
                
                // Solution Image
                solutionImageSection
                
                // AI Feedback
                aiFeedbackSection
                
                // Teacher Feedback (if reviewed)
                if submission.teacherReviewed == true {
                    teacherFeedbackSection
                }
            }
            .padding()
        }
        .navigationTitle("Attempt #\(submission.attemptNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            parseDetailedFeedback()
            await loadSolutionImage()
        }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: 16) {
            // Score Display
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(submission.overallScore)/\(submission.totalQuestions)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(scoreColor)
                }
                
                Spacer()
                
                // Percentage in Circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: scorePercentage / 100)
                        .stroke(scoreColor, lineWidth: 8)
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    Text(percentageString)
                        .font(.title3.bold())
                        .foregroundColor(scoreColor)
                }
            }
            
            Divider()
            
            // Submission Details
            VStack(spacing: 12) {
                InfoRow2(icon: "calendar", label: "Submitted", value: formatDate(submission.submittedAt))
                InfoRow2(icon: "arrow.triangle.2.circlepath", label: "Attempt", value: "#\(submission.attemptNumber)")
                
                if submission.isLate == true {
                    HStack {
                        Image(systemName: "clock.badge.exclamationmark")
                            .foregroundColor(.orange)
                        Text("Late Submission")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                }
                
                HStack {
                    Image(systemName: submission.teacherReviewed == true ? "checkmark.circle.fill" : "clock")
                        .foregroundColor(submission.teacherReviewed == true ? .green : .orange)
                    Text(submission.teacherReviewed == true ? "Reviewed by teacher" : "Pending teacher review")
                        .font(.subheadline)
                        .foregroundColor(submission.teacherReviewed == true ? .green : .orange)
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
            Text("Your Solution")
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
                    description: Text("Unable to load your solution")
                )
                .frame(height: 300)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - AI Feedback Section
    private var aiFeedbackSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("AI Feedback", systemImage: "sparkles")
                .font(.headline)
                .foregroundColor(.purple)
            
            VStack(spacing: 16) {
                // Overall Feedback
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
                            Text("Questions You Got Right")
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
                            Text("Areas to Review")
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
                                Text("Tips for Improvement")
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
                
                // Detailed Question Feedback
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
    
    // MARK: - Teacher Feedback Section
    private var teacherFeedbackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Teacher's Feedback", systemImage: "person.fill")
                .font(.headline)
                .foregroundColor(.blue)
            
            if let notes = submission.teacherNotes, !notes.isEmpty {
                Text(notes)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)
                
                if let reviewedAt = submission.teacherReviewedAt {
                    HStack {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text("Reviewed on \(formatDate(reviewedAt))")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            } else {
                Text("Your teacher has reviewed this submission but didn't leave additional comments.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Helper Properties
    private var scorePercentage: Double {
        (Double(submission.overallScore) / Double(submission.totalQuestions)) * 100
    }
    
    private var scoreColor: Color {
        if scorePercentage >= 90 { return .green }
        else if scorePercentage >= 70 { return .blue }
        else if scorePercentage >= 50 { return .orange }
        else { return .red }
    }
    
    private var percentageString: String {
        String(format: "%.0f%%", scorePercentage)
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
    }
    
    private func loadSolutionImage() async {
        isLoadingImage = true
        
        do {
            let imageData = try await AWSService.shared.downloadFile(key: submission.s3SolutionImageKey)
            await MainActor.run {
                self.solutionImage = UIImage(data: imageData)
            }
        } catch {
            print("Error loading image: \(error.localizedDescription)")
        }
        
        isLoadingImage = false
    }
}
