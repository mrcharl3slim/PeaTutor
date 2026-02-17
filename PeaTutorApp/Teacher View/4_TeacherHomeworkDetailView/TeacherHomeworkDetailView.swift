//
//  TeacherHomeworkDetailView.swift
//  PeaTutorApp
//
//  Sprint 5 Phase 3: Teacher homework detail view with submissions list
//

import SwiftUI
import Amplify

struct TeacherHomeworkDetailView: View {
    let homework: Homework
    let classroom: Classroom
    
    @StateObject private var homeworkService = HomeworkService.shared
    @StateObject private var awsService = AWSService.shared
    
    @State private var submissions: [FullWorksheetSolution] = []
    @State private var analytics: HomeworkAnalytics?
    @State private var studentProfiles: [String: UserProfile] = [:]
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showEditHomework = false
    @State private var showDeleteConfirmation = false
    @State private var selectedTab = 0
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Card
                headerCard
                
                // Quick Stats
                quickStatsSection
                
                // Tab Selector
                tabSelector
                
                // Content based on selected tab
                if selectedTab == 0 {
                    submissionsSection
                } else {
                    analyticsSection
                }
            }
            .padding()
        }
        .navigationTitle(homework.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: { showEditHomework = true }) {
                        Label("Edit Homework", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                        Label("Delete Homework", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditHomework) {
            EditHomeworkView(homework: homework, classroom: classroom) {
                Task {
                    await loadData()
                }
            }
        }
        .alert("Delete Homework", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteHomework()
                }
            }
        } message: {
            Text("Are you sure you want to delete this homework? This will delete all student submissions and cannot be undone.")
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .task {
            await loadData()
        }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title & Status
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(homework.title)
                        .font(.title2.bold())
                    
                    if let worksheet = homework.worksheet {
                        Text(worksheet.title)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Status Badge
                Text(homework.isPublished ? (isOverdue ? "Overdue" : "Active") : "Draft")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(homework.isPublished ? (isOverdue ? Color.red : Color.green) : Color.gray)
                    .cornerRadius(8)
            }
            
            // Description
            if let description = homework.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 8) {
                DetailRow2(icon: "calendar", label: "Due Date", value: formatDueDate())
                DetailRow2(icon: "clock", label: "Assigned", value: formatAssignedDate())
                
                if let points = homework.totalPoints {
                    DetailRow2(icon: "star.fill", label: "Points", value: "\(points)")
                }
                
                if let instructions = homework.instructions, !instructions.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Instructions", systemImage: "doc.text")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        Text(instructions)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Quick Stats
    private var quickStatsSection: some View {
        HStack(spacing: 12) {
            if let analytics = analytics {
                QuickStatCard(
                    icon: "person.2.fill",
                    value: "\(analytics.submittedCount)/\(analytics.totalStudents)",
                    label: "Submitted",
                    color: .blue
                )
                
                QuickStatCard(
                    icon: "checkmark.circle.fill",
                    value: "\(Int(completionPercentage))%",
                    label: "Complete",
                    color: .green
                )
                
                QuickStatCard(
                    icon: "clock.badge.exclamationmark",
                    value: "\(analytics.lateCount)",
                    label: "Late",
                    color: .orange
                )
                
                QuickStatCard(
                    icon: "eye.slash",
                    value: "\(analytics.pendingReviewCount)",
                    label: "Pending",
                    color: .purple
                )
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        Picker("View", selection: $selectedTab) {
            Text("Submissions").tag(0)
            Text("Analytics").tag(1)
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Submissions Section
    private var submissionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Student Submissions")
                .font(.title3.bold())
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if submissions.isEmpty {
                ContentUnavailableView(
                    "No submissions yet",
                    systemImage: "doc.text",
                    description: Text("Student submissions will appear here")
                )
                .frame(height: 200)
            } else {
                // Group by submission status
                let reviewed = submissions.filter { $0.teacherReviewed == true }
                let pending = submissions.filter { $0.teacherReviewed != true }
                
                if !pending.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pending Review (\(pending.count))")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        ForEach(pending, id: \.id) { submission in
                            NavigationLink {
                                TeacherSubmissionDetailView(
                                    submission: submission,
                                    homework: homework,
                                    studentProfile: studentProfiles[submission.userId]
                                )
                            } label: {
                                SubmissionCard2(
                                    submission: submission,
                                    studentProfile: studentProfiles[submission.userId]
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                if !reviewed.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reviewed (\(reviewed.count))")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        ForEach(reviewed, id: \.id) { submission in
                            NavigationLink {
                                TeacherSubmissionDetailView(
                                    submission: submission,
                                    homework: homework,
                                    studentProfile: studentProfiles[submission.userId]
                                )
                            } label: {
                                SubmissionCard2(
                                    submission: submission,
                                    studentProfile: studentProfiles[submission.userId]
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Analytics Section
    private var analyticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Analytics")
                .font(.title3.bold())
            
            if let analytics = analytics {
                VStack(spacing: 16) {
                    // Completion Progress
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Completion Rate")
                                .font(.headline)
                            Spacer()
                            Text("\(Int(completionPercentage))%")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)
                                    .cornerRadius(4)
                                
                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: geometry.size.width * (completionPercentage / 100), height: 8)
                                    .cornerRadius(4)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                    
                    // Detailed Stats
                    VStack(spacing: 12) {
                        AnalyticsRow(label: "Total Students", value: "\(analytics.totalStudents)")
                        AnalyticsRow(label: "Submitted", value: "\(analytics.submittedCount)")
                        AnalyticsRow(label: "Total Submissions", value: "\(analytics.totalSubmissions)")
                        AnalyticsRow(label: "Late Submissions", value: "\(analytics.lateCount)")
                        AnalyticsRow(label: "Reviewed", value: "\(analytics.reviewedCount)")
                        AnalyticsRow(label: "Pending Review", value: "\(analytics.pendingReviewCount)")
                        
                        if let avgAttempts = analytics.averageAttempts {
                            AnalyticsRow(label: "Avg. Attempts", value: String(format: "%.1f", avgAttempts))
                        }
                        
                        if let multipleAttempts = analytics.multipleAttemptsCount, multipleAttempts > 0 {
                            AnalyticsRow(label: "Multiple Attempts", value: "\(multipleAttempts)")
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
    }
    
    // MARK: - Helper Properties
    private var isOverdue: Bool {
        Date() > homework.dueDate.foundationDate
    }
    
    private var completionPercentage: Double {
        guard let analytics = analytics, analytics.totalStudents > 0 else { return 0.0 }
        return (Double(analytics.submittedCount) / Double(analytics.totalStudents)) * 100.0
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
    
    private func loadData() async {
        isLoading = true
        
        do {
            // Load submissions
            let fetchedSubmissions = try await homeworkService.fetchSubmissions(for: homework.id)
            
            // Load analytics
            let fetchedAnalytics = try await homeworkService.fetchAnalytics(for: homework.id)
            
            // Load student profiles
            var profiles: [String: UserProfile] = [:]
            let uniqueStudentIds = Set(fetchedSubmissions.map { $0.userId })
            
            for studentId in uniqueStudentIds {
                if let profile = try await DataStoreService.shared.fetchUserProfile(userId: studentId) {
                    profiles[studentId] = profile
                }
            }
            
            await MainActor.run {
                self.submissions = fetchedSubmissions
                self.analytics = fetchedAnalytics
                self.studentProfiles = profiles
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func deleteHomework() async {
        do {
            try await homeworkService.deleteHomework(homework)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Supporting Views
private struct DetailRow2: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.caption)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption.bold())
        }
    }
}

struct QuickStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.headline.bold())
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
}

struct SubmissionCard2: View {
    let submission: FullWorksheetSolution
    let studentProfile: UserProfile?
    
    var body: some View {
        HStack(spacing: 12) {
            // Student Avatar
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(studentProfile?.initials ?? "?")
                        .font(.headline)
                        .foregroundColor(.blue)
                )
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(studentProfile?.displayName ?? "Unknown Student")
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Label("Attempt \(submission.attemptNumber)", systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if submission.isLate == true {
                        Label("Late", systemImage: "clock.badge.exclamationmark")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    Label(formatDate(submission.submittedAt), systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Score & Status
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(submission.overallScore)/\(submission.totalQuestions)")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                if submission.teacherReviewed == true {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
    
    private func formatDate(_ date: Temporal.DateTime) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date.foundationDate, relativeTo: Date())
    }
}

struct AnalyticsRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
    }
}
