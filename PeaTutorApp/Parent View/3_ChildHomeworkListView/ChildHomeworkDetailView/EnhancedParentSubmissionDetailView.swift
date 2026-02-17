//
//  EnhancedParentSubmissionDetailView.swift
//  PeaTutorApp
//
//  Sprint 7: Enhanced submission view for parents with full AI feedback
//  Sprint 7.4: Added Practice Generation integration
//

import SwiftUI
import Amplify

struct EnhancedParentSubmissionDetailView: View {
    let submission: FullWorksheetSolution
    let homework: Homework
    let child: UserProfile
    
    @State private var solutionImage: UIImage?
    @State private var isLoadingImage = false
    @State private var detailedFeedback: [QuestionFeedback] = []
    @State private var showingPracticeGeneration = false  // Already exists in your file
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Child Header
                    childHeader
                    
                    // Homework Info
                    homeworkInfoCard
                    
                    // Score Card
                    scoreCard
                    
                    // Solution Image
                    solutionImageSection
                    
                    // AI Feedback
                    aiFeedbackSection
                    
                    // NEW: Practice Section (shown when worksheet exists)
                    if homework.worksheet != nil {
                        practiceSection
                    }
                    
                    // Teacher Feedback
                    if submission.teacherReviewed == true {
                        teacherFeedbackSection
                    }
                }
                .padding()
            }
            .navigationTitle("Submission Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        // NEW: Practice Generation Sheet
        .sheet(isPresented: $showingPracticeGeneration) {
            if let worksheet = homework.worksheet {
                PracticeGenerationView(
                    worksheet: worksheet,
                    child: child,
                    concepts: conceptsNeedingWork,
                    suggestedDifficulty: suggestedDifficulty
                )
            } else {
                // Fallback if no worksheet (generate by concepts)
                PracticeGenerationView(
                    child: child,
                    concepts: conceptsNeedingWork,
                    suggestedDifficulty: suggestedDifficulty
                )
            }
        }
        .task {
            parseDetailedFeedback()
            await loadSolutionImage()
        }
    }
    
    // MARK: - Child Header
    private var childHeader: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Text(child.initials)
                        .font(.title2.bold())
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(child.displayName)
                    .font(.title3.bold())
                
                Text("Attempt #\(submission.attemptNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    if submission.teacherReviewed == true {
                        Label("Reviewed", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Label("Pending Review", systemImage: "clock")
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
    
    // MARK: - Homework Info Card
    private var homeworkInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Homework")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(homework.title)
                .font(.headline)
            
            if let worksheet = homework.worksheet {
                Text(worksheet.title ?? "Untitled Worksheet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            VStack(spacing: 8) {
                InfoRow2(icon: "calendar", label: "Submitted", value: formatDate(submission.submittedAt))
                
                if submission.isLate == true {
                    HStack {
                        Image(systemName: "clock.badge.exclamationmark")
                            .foregroundColor(.orange)
                        Text("Late Submission")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Score Card
    private var scoreCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(submission.overallScore)/\(submission.totalQuestions)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(scoreColor)
                }
                
                Spacer()
                
                // Percentage Circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .trim(from: 0, to: scorePercentage / 100)
                        .stroke(scoreColor, lineWidth: 6)
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                    
                    Text(percentageString)
                        .font(.headline)
                        .foregroundColor(scoreColor)
                }
            }
            
            // Performance message
            HStack {
                Image(systemName: performanceIcon)
                    .foregroundColor(scoreColor)
                Text(performanceMessage)
                    .font(.subheadline)
                    .foregroundColor(scoreColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(scoreColor.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Solution Image Section
    private var solutionImageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Child's Solution")
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
                    description: Text("Unable to load solution")
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
            Label("AI Analysis", systemImage: "sparkles")
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
                            Text("Correctly Answered")
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
                            Text("Needs Improvement")
                                .font(.subheadline.bold())
                        }
                        Text(issues.compactMap { $0 }.joined(separator: ", "))
                            .font(.body)
                            .foregroundColor(.orange)
                        
                        Text("Consider reviewing these topics together")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
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
                                Text("Suggestions for Practice")
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
                            Text("Detailed Analysis")
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
    
    // MARK: - Practice Section (NEW - Sprint 7.4)
    private var practiceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Extra Practice", systemImage: "sparkles")
                .font(.headline)
                .foregroundColor(.purple)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Want to help \(child.displayName) improve?")
                    .font(.subheadline)
                
                Text("Generate AI-powered practice problems based on this homework. Problems will be tailored to focus on areas that need more work.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button(action: { showingPracticeGeneration = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Generate Practice Problems")
                            .font(.headline)
                        
                        Text(practiceButtonSubtitle)
                            .font(.caption)
                            .opacity(0.9)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(.white)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            
            // Recommendation hint
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
                
                Text("Recommended: \(suggestedDifficulty.displayName) difficulty based on score")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
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
                Text("The teacher has reviewed this but didn't leave additional comments.")
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
    
    private var performanceMessage: String {
        if scorePercentage >= 90 { return "Excellent work!" }
        else if scorePercentage >= 70 { return "Good job!" }
        else if scorePercentage >= 50 { return "Making progress" }
        else { return "Needs support" }
    }
    
    private var performanceIcon: String {
        if scorePercentage >= 90 { return "star.fill" }
        else if scorePercentage >= 70 { return "hand.thumbsup.fill" }
        else if scorePercentage >= 50 { return "chart.line.uptrend.xyaxis" }
        else { return "exclamationmark.triangle.fill" }
    }
    
    // NEW: Practice button subtitle based on score (Sprint 7.4)
    private var practiceButtonSubtitle: String {
        if scorePercentage < 60 {
            return "Start with easier problems to build confidence"
        } else if scorePercentage < 85 {
            return "Practice similar problems to strengthen skills"
        } else {
            return "Try harder problems for an extra challenge"
        }
    }
    
    // NEW: Suggested difficulty based on score (Sprint 7.4)
    private var suggestedDifficulty: PracticeDifficulty {
        if scorePercentage < 60 {
            return .easier
        } else if scorePercentage < 85 {
            return .similar
        } else {
            return .harder
        }
    }
    
    // NEW: Extract concepts that need work from the submission (Sprint 7.4)
    private var conceptsNeedingWork: [String] {
        // Try to extract from questions with issues
        if let issues = submission.questionsWithIssues {
            return issues.compactMap { $0 }
        }
        return []
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
