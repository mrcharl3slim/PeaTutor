//
//  StudentProgressView.swift
//  PeaTutorApp
//
//  Sprint 5 Phase 4: Individual student progress tracking
//

import SwiftUI
import Amplify

struct StudentProgressView: View {
    let studentId: String
    let classroom: Classroom
    let studentProfile: UserProfile?
    
    @StateObject private var homeworkService = HomeworkService.shared
    @State private var progress: StudentProgress?
    @State private var homework: [Homework] = []
    @State private var submissions: [String: [FullWorksheetSolution]] = [:] // homeworkId: submissions
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Student Header
                studentHeader
                
                // Curriculum Progress
                curriculumProgressSection
                
                // Overall Stats
                overallStatsSection
                
                // Progress Chart
                progressChartSection
                
                // Homework History
                homeworkHistorySection
                
                // Strengths & Weaknesses
                if let progress = progress {
                    strengthsWeaknessesSection(progress: progress)
                }
            }
            .padding()
        }
        .navigationTitle("Student Progress")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadProgress()
        }
        .refreshable {
            await loadProgress()
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Student Header
    private var studentHeader: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 70, height: 70)
                .overlay(
                    Text(studentProfile?.initials ?? "?")
                        .font(.title.bold())
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(studentProfile?.displayName ?? "Unknown Student")
                    .font(.title2.bold())
                
                if let email = studentProfile?.email {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let gradeLevel = studentProfile?.gradeLevel {
                    Label(gradeLevel, systemImage: "graduationcap")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Curriculum Progress Section
    private var curriculumProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Curriculum Progress")
                .font(.title3.bold())
                
            CurriculumStrandProgressView(
                studentId: studentId,
                classroomId: classroom.id,
                gradeLevel: classroom.gradeLevel ?? "Primary 1",
                studentName: studentProfile?.displayName,
                showHeader: false,  // We have our own title
                accentColor: .blue
            )
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
            } else if let progress = progress {
                HStack(spacing: 12) {
                    StudentStatCard(
                        icon: "checkmark.circle.fill",
                        value: "\(progress.totalHomeworkCompleted)",
                        label: "Completed",
                        color: .green
                    )
                    
                    StudentStatCard(
                        icon: "clock",
                        value: "\(progress.totalHomeworkAssigned - progress.totalHomeworkCompleted)",
                        label: "Pending",
                        color: .orange
                    )
                    
                    StudentStatCard(
                        icon: "clock.badge.exclamationmark",
                        value: "\(progress.totalHomeworkLate)",
                        label: "Late",
                        color: .red
                    )
                }
                
                HStack(spacing: 12) {
                    StudentStatCard(
                        icon: "arrow.triangle.2.circlepath",
                        value: progress.averageAttemptsPerHomework.map { String(format: "%.1f", $0) } ?? "0",
                        label: "Avg Attempts",
                        color: .blue
                    )
                    
                    StudentStatCard(
                        icon: "percent",
                        value: "\(Int(completionRate))%",
                        label: "On-Time Rate",
                        color: .purple
                    )
                }
            }
        }
    }
    
    // MARK: - Progress Chart
    private var progressChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress Overview")
                .font(.title3.bold())
            
            if let progress = progress, progress.totalHomeworkAssigned > 0 {
                VStack(spacing: 16) {
                    // Completion Progress Bar
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Completion Rate")
                                .font(.headline)
                            Spacer()
                            Text("\(Int(completionRate))%")
                                .font(.headline)
                                .foregroundColor(completionRateColor)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 12)
                                    .cornerRadius(6)
                                
                                Rectangle()
                                    .fill(completionRateColor)
                                    .frame(width: geometry.size.width * (completionRate / 100), height: 12)
                                    .cornerRadius(6)
                            }
                        }
                        .frame(height: 12)
                        
                        HStack {
                            Text("\(progress.totalHomeworkCompleted) of \(progress.totalHomeworkAssigned) completed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                    
                    // On-Time Performance
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("On-Time Performance")
                                .font(.headline)
                            Spacer()
                            Text("\(Int(onTimeRate))%")
                                .font(.headline)
                                .foregroundColor(onTimeRateColor)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 12)
                                    .cornerRadius(6)
                                
                                Rectangle()
                                    .fill(onTimeRateColor)
                                    .frame(width: geometry.size.width * (onTimeRate / 100), height: 12)
                                    .cornerRadius(6)
                            }
                        }
                        .frame(height: 12)
                        
                        HStack {
                            Text("\(progress.totalHomeworkCompleted - progress.totalHomeworkLate) on time, \(progress.totalHomeworkLate) late")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                }
            } else {
                ContentUnavailableView(
                    "No progress data",
                    systemImage: "chart.bar",
                    description: Text("Progress will appear after homework is assigned")
                )
                .frame(height: 200)
            }
        }
    }
    
    // MARK: - Homework History
    private var homeworkHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Homework History")
                .font(.title3.bold())
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if homework.isEmpty {
                ContentUnavailableView(
                    "No homework assigned",
                    systemImage: "doc.text",
                    description: Text("Homework history will appear here")
                )
                .frame(height: 200)
            } else {
                VStack(spacing: 12) {
                    ForEach(homework, id: \.id) { hw in
                        StudentHomeworkHistoryCard(
                            homework: hw,
                            submissions: submissions[hw.id] ?? []
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Strengths & Weaknesses
    private func strengthsWeaknessesSection(progress: StudentProgress) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Insights")
                .font(.title3.bold())
            
            VStack(spacing: 16) {
                // Strengths
                if let strengths = progress.strengthAreas, !strengths.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Strengths", systemImage: "star.fill")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        ForEach(strengths.split(separator: ",").map(String.init), id: \.self) { strength in
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text(strength.trimmingCharacters(in: .whitespaces))
                                    .font(.body)
                            }
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.05))
                    .cornerRadius(12)
                }
                
                // Areas for Improvement
                if let improvements = progress.improvementAreas, !improvements.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Areas for Improvement", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        ForEach(improvements.split(separator: ",").map(String.init), id: \.self) { area in
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                Text(area.trimmingCharacters(in: .whitespaces))
                                    .font(.body)
                            }
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.05))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var completionRate: Double {
        guard let progress = progress, progress.totalHomeworkAssigned > 0 else { return 0.0 }
        return (Double(progress.totalHomeworkCompleted) / Double(progress.totalHomeworkAssigned)) * 100
    }
    
    private var onTimeRate: Double {
        guard let progress = progress, progress.totalHomeworkCompleted > 0 else { return 100.0 }
        let onTime = progress.totalHomeworkCompleted - progress.totalHomeworkLate
        return (Double(onTime) / Double(progress.totalHomeworkCompleted)) * 100
    }
    
    private var completionRateColor: Color {
        if completionRate >= 80 { return .green }
        if completionRate >= 60 { return .orange }
        return .red
    }
    
    private var onTimeRateColor: Color {
        if onTimeRate >= 80 { return .green }
        if onTimeRate >= 60 { return .orange }
        return .red
    }
    
    // MARK: - Load Data
    private func loadProgress() async {
        isLoading = true
        
        do {
            // Load student progress
            let fetchedProgress = try await homeworkService.getStudentProgress(
                studentId: studentId,
                classroom: classroom
            )
            
            // Load all homework for this classroom
            let fetchedHomework = try await homeworkService.fetchClassroomHomework(
                classroomId: classroom.id,
                publishedOnly: true
            )
            
            // Load submissions for each homework
            var allSubmissions: [String: [FullWorksheetSolution]] = [:]
            for hw in fetchedHomework {
                let hwSubmissions = try await homeworkService.fetchStudentSubmissions(
                    homeworkId: hw.id,
                    studentId: studentId
                )
                allSubmissions[hw.id] = hwSubmissions
            }
            
            await MainActor.run {
                self.progress = fetchedProgress
                self.homework = fetchedHomework
                self.submissions = allSubmissions
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - Supporting Views
struct StudentStatCard: View {
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
                .font(.title2.bold())
            Text(label)
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

struct StudentHomeworkHistoryCard: View {
    let homework: Homework
    let submissions: [FullWorksheetSolution]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(homework.title)
                        .font(.headline)
                    
                    Text("Due: \(formatDueDate())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                statusBadge
            }
            
            if !submissions.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(submissions, id: \.id) { submission in
                        HStack {
                            Label("Attempt \(submission.attemptNumber)", systemImage: "arrow.triangle.2.circlepath")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(submission.overallScore)/\(submission.totalQuestions)")
                                .font(.caption.bold())
                                .foregroundColor(.blue)
                            
                            if submission.isLate == true {
                                Image(systemName: "clock.badge.exclamationmark")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                            }
                            
                            if submission.teacherReviewed == true {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
    
    private var statusBadge: some View {
        Group {
            if !submissions.isEmpty {
                Text("Submitted")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .cornerRadius(6)
            } else if isOverdue {
                Text("Missing")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .cornerRadius(6)
            } else {
                Text("Pending")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .cornerRadius(6)
            }
        }
    }
    
    private var isOverdue: Bool {
        Date() > homework.dueDate.foundationDate
    }
    
    private func formatDueDate() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: homework.dueDate.foundationDate, relativeTo: Date())
    }
}
