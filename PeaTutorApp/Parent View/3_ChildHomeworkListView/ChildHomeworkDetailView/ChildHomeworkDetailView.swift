//
//  ChildHomeworkDetailView.swift
//  PeaTutorApp
//
//  Sprint 6: Parent Dashboard - Detailed homework submission view
//

import SwiftUI
import Amplify

struct ChildHomeworkDetailView: View {
    let homework: Homework
    let child: UserProfile
    let submissions: [FullWorksheetSolution]
    
    @StateObject private var awsService = AWSService.shared
    @State private var submissionImages: [String: Data] = [:] // submissionId: imageData
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedSubmission: FullWorksheetSolution?
    
    @State private var showingPracticeGeneration = false
    @State private var worksheetForPractice: Worksheet?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Card
                headerCard
                
                // Submission History
                if submissions.isEmpty {
                    notSubmittedCard
                } else {
                    submissionHistorySection
                }
                
                // Homework Details
                homeworkDetailsSection
            }
            .padding()
        }
        .navigationTitle(homework.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadSubmissionImages()
        }
        .sheet(item: $selectedSubmission) { submission in
            EnhancedParentSubmissionDetailView(
                    submission: submission,
                    homework: homework,
                    child: child
                )
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .sheet(isPresented: $showingPracticeGeneration) {
            if let worksheet = worksheetForPractice {
                PracticeGenerationView(
                    worksheet: worksheet,
                    child: child,
                    concepts: [],
                    suggestedDifficulty: suggestedDifficulty
                )
            }
        }
    }
    
    // MARK: - Suggested Difficulty

    private var suggestedDifficulty: PracticeDifficulty {
        // If there are submissions, base difficulty on the latest score
        guard let latestSubmission = submissions.max(by: { $0.attemptNumber < $1.attemptNumber }) else {
            return .similar
        }
        
        let score = Double(latestSubmission.overallScore) / Double(max(latestSubmission.totalQuestions, 1)) * 100
        
        if score < 60 {
            return .easier
        } else if score < 85 {
            return .similar
        } else {
            return .harder
        }
    }
    
    // MARK: - Header Card
    
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title & Worksheet
            VStack(alignment: .leading, spacing: 4) {
                Text(homework.title)
                    .font(.title2.bold())
                
                if let worksheet = homework.worksheet {
                    Text(worksheet.title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Info Grid
            VStack(spacing: 12) {
                InfoRow2(
                    icon: "person.fill",
                    label: "Student",
                    value: child.displayName
                )
                
                InfoRow2(
                    icon: "calendar",
                    label: "Due Date",
                    value: formatDueDate(),
                )
                
                InfoRow2(
                    icon: "clock",
                    label: "Assigned",
                    value: formatAssignedDate()
                )
                
                if let totalPoints = homework.totalPoints {
                    InfoRow2(
                        icon: "star.fill",
                        label: "Total Points",
                        value: "\(totalPoints)"
                    )
                }
                
                InfoRow2(
                    icon: "checkmark.circle.fill",
                    label: "Status",
                    value: statusText,
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Not Submitted Card
    
    private var notSubmittedCard: some View {
        VStack(spacing: 16) {
            Image(systemName: isOverdue ? "exclamationmark.triangle.fill" : "clock.fill")
                .font(.system(size: 50))
                .foregroundColor(isOverdue ? .red : .orange)
            
            Text(isOverdue ? "Overdue - Not Submitted" : "Pending Submission")
                .font(.headline)
            
            Text(isOverdue ? 
                 "\(child.displayName) has not submitted this homework yet. The due date has passed." :
                 "\(child.displayName) hasn't submitted this homework yet. Due \(formatDueDate())."
            )
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Submission History Section
    
    private var submissionHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Submission History", systemImage: "clock.arrow.circlepath")
                    .font(.title3.bold())
                
                Spacer()
                
                Text("\(submissions.count) attempt\(submissions.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ForEach(submissions.sorted(by: { $0.attemptNumber > $1.attemptNumber }), id: \.id) { submission in
                Button(action: {
                    selectedSubmission = submission
                }) {
                    SubmissionCard(
                        submission: submission,
                        hasImage: submissionImages[submission.id] != nil
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // NEW: Practice Similar Problems Button
            if !submissions.isEmpty, let worksheet = homework.worksheet {
                practiceMoreButton(worksheet: worksheet)
            }
        }
    }
    
    // MARK: - Homework Details Section
    
    private var homeworkDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Homework Details")
                .font(.title3.bold())
            
            VStack(alignment: .leading, spacing: 12) {
                if let description = homework.description, !description.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                        
                        Text(description)
                            .font(.body)
                    }
                }
                
                if let classroom = homework.classroom {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Class")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "building.2")
                                .foregroundColor(.blue)
                            Text(classroom.className)
                                .font(.body)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Computed Properties
    
    private var isOverdue: Bool {
        Date() > homework.dueDate.foundationDate
    }
    
    private var statusText: String {
        if !submissions.isEmpty {
            return "Submitted"
        } else if isOverdue {
            return "Overdue"
        } else {
            return "Pending"
        }
    }
    
    private var statusColor: Color {
        if !submissions.isEmpty {
            return .green
        } else if isOverdue {
            return .red
        } else {
            return .orange
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDueDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: homework.dueDate.foundationDate)
    }
    
    private func formatAssignedDate() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: homework.assignedDate.foundationDate, relativeTo: Date())
    }
    
    private func loadSubmissionImages() async {
        isLoading = true
        defer { isLoading = false }
        
        var images: [String: Data] = [:]
        
        for submission in submissions {
            do {
                let imageData = try await awsService.downloadFile(key: submission.s3SolutionImageKey)
                images[submission.id] = imageData
            } catch {
                print("⚠️ Failed to load image for submission \(submission.id): \(error)")
            }
        }
        
        await MainActor.run {
            self.submissionImages = images
        }
    }

    // MARK: - Practice More Button

    private func practiceMoreButton(worksheet: Worksheet) -> some View {
        Button(action: {
            worksheetForPractice = worksheet
            showingPracticeGeneration = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Practice Similar Problems")
                        .font(.subheadline.bold())
                    
                    Text("Generate AI-powered practice based on this worksheet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
            }
            .foregroundColor(.primary)
            .padding()
            .background(
                LinearGradient(
                    colors: [.purple.opacity(0.1), .blue.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Submission Card

private struct SubmissionCard: View {
    let submission: FullWorksheetSolution
    let hasImage: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Attempt Icon
            ZStack {
                Circle()
                    .fill(scoreColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text("#\(submission.attemptNumber)")
                    .font(.headline)
                    .foregroundColor(scoreColor)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Attempt \(submission.attemptNumber)")
                        .font(.headline)
                    
                    Spacer()
                    
                    // Score
                    Text("\(submission.overallScore)/\(submission.totalQuestions)")
                        .font(.headline.bold())
                        .foregroundColor(scoreColor)
                }
                
                // Date
                Text(formatSubmittedDate())
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Badges
                HStack(spacing: 8) {
                    if submission.isLate == true {
                        StatusBadge1(text: "Late", color: .orange)
                    }
                    
                    if submission.teacherReviewed == true {
                        StatusBadge1(text: "Reviewed", color: .green)
                    } else {
                        StatusBadge1(text: "Pending Review", color: .gray)
                    }
                    
                    if hasImage {
                        StatusBadge1(text: "Has Image", color: .blue)
                    }
                }
            }
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
    
    private var scoreColor: Color {
        let percentage = Double(submission.overallScore) / Double(submission.totalQuestions) * 100
        
        if percentage >= 90 {
            return .green
        } else if percentage >= 70 {
            return .blue
        } else if percentage >= 50 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func formatSubmittedDate() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Submitted \(formatter.localizedString(for: submission.submittedAt.foundationDate, relativeTo: Date()))"
    }
}

// MARK: - OLD Submission Detail Sheet

struct SubmissionDetailSheet: View {
    let submission: FullWorksheetSolution
    let homework: Homework
    let imageData: Data?
    
    @Environment(\.dismiss) var dismiss
    @State private var showingFullImage = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Score Card
                    scoreCard
                    
                    // Submitted Work Image
                    if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                        submittedWorkSection(image: uiImage)
                    }
                    
                    // Overall Feedback
                    if !submission.overallFeedback.isEmpty {
                            feedbackSection(feedback: submission.overallFeedback)
                    }
                    
                    // Submission Details
                    detailsSection
                }
                .padding()
            }
            .navigationTitle("Attempt \(submission.attemptNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingFullImage) {
                if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                    FullImageView(image: uiImage)
                }
            }
        }
    }
    
    // MARK: - Score Card
    
    private var scoreCard: some View {
        HStack(spacing: 20) {
            // Score Circle
            ZStack {
                Circle()
                    .stroke(scoreColor.opacity(0.3), lineWidth: 8)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: scorePercentage / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text("\(submission.overallScore)")
                        .font(.title.bold())
                        .foregroundColor(scoreColor)
                    
                    Text("of \(submission.totalQuestions)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Details
            VStack(alignment: .leading, spacing: 8) {
                Text("\(Int(scorePercentage))%")
                    .font(.title.bold())
                    .foregroundColor(scoreColor)
                
                Text(scoreDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    if submission.isLate == true {
                        StatusBadge1(text: "Late", color: .orange)
                    }
                    
                    if submission.teacherReviewed == true {
                        StatusBadge1(text: "Reviewed", color: .green)
                    } else {
                        StatusBadge1(text: "Pending Review", color: .gray)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Submitted Work Section
    
    private func submittedWorkSection(image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Submitted Work")
                .font(.title3.bold())
            
            Button(action: { showingFullImage = true }) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 300)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.separator), lineWidth: 1)
                    )
                    .overlay(
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(8)
                                    .padding(8)
                            }
                        }
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Feedback Section
    
    private func feedbackSection(feedback: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Teacher Feedback", systemImage: "text.bubble.fill")
                .font(.title3.bold())
            
            Text(feedback)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
        }
    }
    
    // MARK: - Details Section
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Submission Details")
                .font(.title3.bold())
            
            VStack(spacing: 12) {
                DetailRow3(label: "Submitted", value: formatDate(submission.submittedAt))
                DetailRow3(label: "Attempt Number", value: "#\(submission.attemptNumber)")
                DetailRow3(label: "Questions Answered", value: "\(submission.overallScore) of \(submission.totalQuestions)")
                DetailRow3(label: "Review Status", value: submission.teacherReviewed == true ? "Reviewed by teacher" : "Pending review")
                
                if submission.isLate == true {
                    DetailRow3(label: "Submission", value: "Late", valueColor: .orange)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Computed Properties
    
    private var scorePercentage: Double {
        (Double(submission.overallScore) / Double(submission.totalQuestions)) * 100
    }
    
    private var scoreColor: Color {
        if scorePercentage >= 90 {
            return .green
        } else if scorePercentage >= 70 {
            return .blue
        } else if scorePercentage >= 50 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var scoreDescription: String {
        if scorePercentage >= 90 {
            return "Excellent work!"
        } else if scorePercentage >= 70 {
            return "Good job!"
        } else if scorePercentage >= 50 {
            return "Needs improvement"
        } else {
            return "Needs more practice"
        }
    }
    
    private func formatDate(_ date: Temporal.DateTime) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date.foundationDate)
    }
}

// MARK: - Detail Row

private struct DetailRow3: View {
    let label: String
    let value: String
    var valueColor: Color?
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(valueColor ?? .primary)
        }
    }
}

// MARK: - Full Image View

struct FullImageView: View {
    let image: UIImage
    @Environment(\.dismiss) var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { _ in
                                lastScale = scale
                                if scale < 1 {
                                    withAnimation {
                                        scale = 1
                                        lastScale = 1
                                    }
                                } else if scale > 4 {
                                    withAnimation {
                                        scale = 4
                                        lastScale = 4
                                    }
                                }
                            }
                    )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}



extension FullWorksheetSolution: Identifiable {
    // Already has 'id' property from Amplify Model
    // This explicit conformance helps the compiler
}
