//
//  ClassAnalyticsDashboardView.swift
//  PeaTutorApp
//
//  Sprint 5 Phase 4: Class-level analytics dashboard
//

import SwiftUI
import Amplify
import Charts

struct ClassAnalyticsDashboardView: View {
    let classroom: Classroom
    
    @StateObject private var homeworkService = HomeworkService.shared
    @State private var homework: [Homework] = []
    @State private var allAnalytics: [HomeworkAnalytics] = []
    @State private var studentProfiles: [String: UserProfile] = [:]
    @State private var studentProgress: [StudentProgress] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var allSubmissions: [FullWorksheetSolution] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Overall Stats
                overallStatsSection
                
                // Curriculum Overview
                classCurriculumOverviewSection
                
                // Homework Performance Chart
                homeworkPerformanceChart
                
                // Students Needing Help
                studentsNeedingHelpSection
                
                // Recent Activity
                recentActivitySection
            }
            .padding()
        }
        .navigationTitle("Class Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadAnalytics()
        }
        .refreshable {
            await loadAnalytics()
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Overall Stats
    private var overallStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overall Statistics")
                .font(.title3.bold())
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                HStack(spacing: 12) {
                    OverallStatCard(
                        title: "Homework",
                        value: "\(homework.filter { $0.isPublished }.count)",
                        icon: "doc.text.fill",
                        color: .blue
                    )
                    
                    OverallStatCard(
                        title: "Avg Completion",
                        value: "\(Int(averageCompletionRate))%",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                    
                    OverallStatCard(
                        title: "Avg Score",
                        value: "\(Int(averageScore))%",
                        icon: "star.fill",
                        color: .orange
                    )
                }
            }
        }
    }
    
    // MARK: - Class Curriculum Overview Section
    private var classCurriculumOverviewSection: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Curriculum Progress")
                        .font(.title3.bold())
                    
                    Spacer()
                    
                    NavigationLink {
                        ClassCurriculumDetailView(classroom: classroom)
                    } label: {
                        Text("Details")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                ClassCurriculumOverviewCard(
                    classroomId: classroom.id,
                    gradeLevel: classroom.gradeLevel ?? "Primary 3"
                )
            }
        }
    
    // MARK: - Homework Performance Chart
    private var homeworkPerformanceChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Homework Performance")
                .font(.title3.bold())
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 250)
            } else if homework.isEmpty {
                ContentUnavailableView(
                    "No homework data",
                    systemImage: "chart.bar",
                    description: Text("Assign homework to see performance metrics")
                )
                .frame(height: 250)
            } else {
                VStack(spacing: 12) {
                    ForEach(homeworkChartData, id: \.homework.id) { data in
                        HomeworkProgressBar(
                            homework: data.homework,
                            completionRate: data.completionRate,
                            submittedCount: data.submittedCount,
                            totalStudents: data.totalStudents
                        )
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
            }
        }
    }
    
    // MARK: - Students Needing Help
    private var studentsNeedingHelpSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Students Needing Help", systemImage: "exclamationmark.triangle.fill")
                    .font(.title3.bold())
                    .foregroundColor(.orange)
                
                Spacer()
            }
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if strugglingStudents.isEmpty {
                ContentUnavailableView(
                    "All students on track",
                    systemImage: "checkmark.circle.fill",
                    description: Text("No students need immediate attention")
                )
                .frame(height: 150)
            } else {
                VStack(spacing: 12) {
                    ForEach(strugglingStudents, id: \.studentId) { student in
                        NavigationLink {
                            StudentProgressView(
                                studentId: student.studentId,
                                classroom: classroom,
                                studentProfile: studentProfiles[student.studentId]
                            )
                        } label: {
                            StrugglingStudentCard(
                                studentProfile: studentProfiles[student.studentId],
                                progress: student,
                                totalHomework: homework.filter { $0.isPublished }.count
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    // MARK: - Recent Activity
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.title3.bold())
            
            if recentSubmissions.isEmpty {
                ContentUnavailableView(
                    "No recent activity",
                    systemImage: "clock",
                    description: Text("Recent submissions will appear here")
                )
                .frame(height: 150)
            } else {
                VStack(spacing: 12) {
                    ForEach(recentSubmissions.prefix(5), id: \.id) { submission in
                        RecentActivityCard(
                            submission: submission,
                            studentProfile: studentProfiles[submission.userId],
                            homework: homework.first(where: { $0.id == submission.homework?.id })
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var averageCompletionRate: Double {
        guard !allAnalytics.isEmpty else { return 0.0 }
        
        let totalRate = allAnalytics.reduce(0.0) { sum, analytics in
            guard analytics.totalStudents > 0 else { return sum }
            return sum + (Double(analytics.submittedCount) / Double(analytics.totalStudents) * 100)
        }
        
        return totalRate / Double(allAnalytics.count)
    }
    
    private var averageScore: Double {
        guard !allSubmissions.isEmpty else { return 0.0 }
        
        let totalScore = allSubmissions.reduce(0.0) { sum, submission in
            guard submission.totalQuestions > 0 else { return sum }
            let percentage = (Double(submission.overallScore) / Double(submission.totalQuestions)) * 100
            return sum + percentage
        }
        
        return totalScore / Double(allSubmissions.count)
    }
    
    private var homeworkChartData: [(homework: Homework, completionRate: Double, submittedCount: Int, totalStudents: Int)] {
        homework.filter { $0.isPublished }.compactMap { hw in
            guard let analytics = allAnalytics.first(where: { $0.homeworkId == hw.id }) else { return nil }
            guard analytics.totalStudents > 0 else { return nil }
            
            let rate = (Double(analytics.submittedCount) / Double(analytics.totalStudents)) * 100
            return (hw, rate, analytics.submittedCount, analytics.totalStudents)
        }.sorted { $0.completionRate > $1.completionRate }
    }
    
    private var strugglingStudents: [StudentProgress] {
        studentProgress.filter { progress in
            let completionRate = progress.totalHomeworkAssigned > 0 ?
                Double(progress.totalHomeworkCompleted) / Double(progress.totalHomeworkAssigned) : 0
            let lateRate = progress.totalHomeworkCompleted > 0 ?
                Double(progress.totalHomeworkLate) / Double(progress.totalHomeworkCompleted) : 0
            
            return completionRate < 0.7 || lateRate > 0.3 || 
                   (progress.totalHomeworkAssigned - progress.totalHomeworkCompleted) > 2
        }.sorted { p1, p2 in
            let missing1 = p1.totalHomeworkAssigned - p1.totalHomeworkCompleted
            let missing2 = p2.totalHomeworkAssigned - p2.totalHomeworkCompleted
            return missing1 > missing2
        }
    }
    
    private var recentSubmissions: [FullWorksheetSolution] {
        // Sort all submissions by submission date (most recent first)
        return allSubmissions
            .sorted { $0.submittedAt.foundationDate > $1.submittedAt.foundationDate }
    }
    
    // MARK: - Load Data
    private func loadAnalytics() async {
        isLoading = true
        
        do {
            // Load all homework for this classroom
            let fetchedHomework = try await homeworkService.fetchClassroomHomework(
                classroomId: classroom.id,
                publishedOnly: false
            )
            
            // Load analytics for each homework
            var analytics: [HomeworkAnalytics] = []
            for hw in fetchedHomework where hw.isPublished {
                if let hwAnalytics = try await homeworkService.fetchAnalytics(for: hw.id) {
                    analytics.append(hwAnalytics)
                }
            }
            
            // Load student progress
            let allMembers = try await Amplify.DataStore.query(ClassroomMembership.self)
            let classMembers = allMembers.filter {
                $0.classroom?.id == classroom.id && $0.status == .approved
            }
            
            var profiles: [String: UserProfile] = [:]
            var progress: [StudentProgress] = []
            
            for member in classMembers {
                // Load profile
                if let profile = try await DataStoreService.shared.fetchUserProfile(userId: member.studentId) {
                    profiles[member.studentId] = profile
                }
                
                // Load progress
                let studentProgress = try await homeworkService.getStudentProgress(
                    studentId: member.studentId,
                    classroom: classroom
                )
                progress.append(studentProgress)
            }
            
            var submissions: [FullWorksheetSolution] = []
            for hw in fetchedHomework where hw.isPublished {
                let hwSubmissions = try await homeworkService.fetchSubmissions(for: hw.id)
                submissions.append(contentsOf: hwSubmissions)
            }
            
            await MainActor.run {
                self.homework = fetchedHomework
                self.allAnalytics = analytics
                self.studentProfiles = profiles
                self.studentProgress = progress
                self.allSubmissions = submissions
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - Supporting Views
struct OverallStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title.bold())
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
}

struct HomeworkProgressBar: View {
    let homework: Homework
    let completionRate: Double
    let submittedCount: Int
    let totalStudents: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(homework.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                
                Spacer()
                
                Text("\(submittedCount)/\(totalStudents)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(completionColor)
                        .frame(width: geometry.size.width * (completionRate / 100), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            Text("\(Int(completionRate))% complete")
                .font(.caption2)
                .foregroundColor(completionColor)
        }
    }
    
    private var completionColor: Color {
        if completionRate >= 80 { return .green }
        if completionRate >= 50 { return .orange }
        return .red
    }
}

struct StrugglingStudentCard: View {
    let studentProfile: UserProfile?
    let progress: StudentProgress
    let totalHomework: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.orange.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(studentProfile?.initials ?? "?")
                        .font(.subheadline.bold())
                        .foregroundColor(.orange)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(studentProfile?.displayName ?? "Unknown Student")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    Label("\(missingCount) missing", systemImage: "xmark.circle")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    if progress.totalHomeworkLate > 0 {
                        Label("\(progress.totalHomeworkLate) late", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
    
    private var missingCount: Int {
        progress.totalHomeworkAssigned - progress.totalHomeworkCompleted
    }
}

struct RecentActivityCard: View {
    let submission: FullWorksheetSolution
    let studentProfile: UserProfile?
    let homework: Homework?
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(studentProfile?.initials ?? "?")
                        .font(.subheadline.bold())
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(studentProfile?.displayName ?? "Unknown")
                    .font(.subheadline.bold())
                
                Text(homework?.title ?? "Unknown homework")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(submission.overallScore)/\(submission.totalQuestions)")
                    .font(.caption.bold())
                    .foregroundColor(.blue)
                
                Text(formatDate(submission.submittedAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
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
