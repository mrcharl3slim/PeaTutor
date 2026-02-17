//
//  ChildHomeworkListView.swift
//  PeaTutorApp
//
//  Sprint 6: Parent Dashboard - Child homework list view
//

import SwiftUI
import Amplify

struct ChildHomeworkListView: View {
    let child: UserProfile
    
    @StateObject private var homeworkService = HomeworkService.shared
    @State private var homework: [Homework] = []
    @State private var submissions: [String: [FullWorksheetSolution]] = [:] // homeworkId: [submissions]
    @State private var classrooms: [String: Classroom] = [:] // classroomId: Classroom
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedFilter: HomeworkFilter = .all
    
    enum HomeworkFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case submitted = "Submitted"
        case overdue = "Overdue"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter Picker
            Picker("Filter", selection: $selectedFilter) {
                ForEach(HomeworkFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .background(Color(.systemGroupedBackground))
            
            // Content
            if isLoading {
                ProgressView("Loading homework...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredHomework.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredHomework, id: \.id) { hw in
                            NavigationLink(destination: ChildHomeworkDetailView(
                                homework: hw,
                                child: child,
                                submissions: submissions[hw.id] ?? []
                            )) {
                                ParentHomeworkCard(
                                    homework: hw,
                                    submissions: submissions[hw.id] ?? [],
                                    classroom: classrooms[hw.classroom?.id ?? ""]
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("\(child.displayName)'s Homework")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    Task { await loadData() }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
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
        .refreshable {
            await loadData()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: selectedFilter == .all ? "doc.text" : "checkmark.circle")
                .font(.system(size: 60))
                .foregroundStyle(.gray.gradient)
            
            Text(emptyStateTitle)
                .font(.headline)
            
            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxHeight: .infinity)
        .padding()
    }
    
    private var emptyStateTitle: String {
        switch selectedFilter {
        case .all:
            return "No Homework"
        case .pending:
            return "All Caught Up!"
        case .submitted:
            return "No Submissions Yet"
        case .overdue:
            return "Nothing Overdue"
        }
    }
    
    private var emptyStateMessage: String {
        switch selectedFilter {
        case .all:
            return "\(child.displayName) doesn't have any homework assigned yet"
        case .pending:
            return "\(child.displayName) has submitted all assigned homework"
        case .submitted:
            return "\(child.displayName) hasn't submitted any homework yet"
        case .overdue:
            return "\(child.displayName) has no overdue homework"
        }
    }
    
    // MARK: - Filtered Homework
    
    private var filteredHomework: [Homework] {
        switch selectedFilter {
        case .all:
            return homework
        case .pending:
            return homework.filter { hw in
                let hwSubmissions = submissions[hw.id] ?? []
                return hwSubmissions.isEmpty && !isOverdue(hw)
            }
        case .submitted:
            return homework.filter { hw in
                !(submissions[hw.id] ?? []).isEmpty
            }
        case .overdue:
            return homework.filter { hw in
                let hwSubmissions = submissions[hw.id] ?? []
                return hwSubmissions.isEmpty && isOverdue(hw)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func isOverdue(_ homework: Homework) -> Bool {
        Date() > homework.dueDate.foundationDate
    }
    
    private func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch homework
            let fetchedHomework = try await homeworkService.fetchStudentHomework(studentId: child.userId)
            
            // Fetch submissions for each homework
            var submissionsMap: [String: [FullWorksheetSolution]] = [:]
            var classroomsMap: [String: Classroom] = [:]
            
            for hw in fetchedHomework {
                // Get submissions
                let hwSubmissions = try await homeworkService.fetchStudentSubmissions(
                    homeworkId: hw.id,
                    studentId: child.userId
                )
                submissionsMap[hw.id] = hwSubmissions
                
                // Get classroom
                if let classroom = hw.classroom {
                    classroomsMap[classroom.id] = classroom
                }
            }
            
            await MainActor.run {
                self.homework = fetchedHomework
                self.submissions = submissionsMap
                self.classrooms = classroomsMap
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Parent Homework Card

struct ParentHomeworkCard: View {
    let homework: Homework
    let submissions: [FullWorksheetSolution]
    let classroom: Classroom?
    
    var body: some View {
        VStack(spacing: 0) {
            // Class Header
            if let classroom = classroom {
                HStack {
                    Image(systemName: "building.2")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text(classroom.className)
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
            }
            
            // Homework Content
            HStack(spacing: 16) {
                // Status Icon
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: statusIcon)
                        .font(.title3)
                        .foregroundColor(statusColor)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(homework.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    // Due date
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(dueText)
                            .font(.caption)
                    }
                    .foregroundColor(isOverdue ? .red : .secondary)
                    
                    // Status badges
                    HStack(spacing: 8) {
                        // Submission status
                        StatusBadge1(
                            text: statusText,
                            color: statusColor
                        )
                        
                        // Score badge (if submitted)
                        if let latestSubmission = submissions.max(by: { $0.attemptNumber < $1.attemptNumber }) {
                            StatusBadge1(
                                text: "\(latestSubmission.overallScore)/\(latestSubmission.totalQuestions)",
                                color: scoreColor(for: latestSubmission)
                            )
                        }
                        
                        // Attempt count (if multiple attempts)
                        if submissions.count > 1 {
                            StatusBadge1(
                                text: "\(submissions.count) attempts",
                                color: .purple
                            )
                        }
                        
                        // Late badge
                        if submissions.contains(where: { $0.isLate == true }) {
                            StatusBadge1(
                                text: "Late",
                                color: .orange
                            )
                        }
                        
                        // Review status
                        if let latest = submissions.max(by: { $0.attemptNumber < $1.attemptNumber }),
                           latest.teacherReviewed == true {
                            StatusBadge1(
                                text: "Reviewed",
                                color: .green
                            )
                        }
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
    
    // MARK: - Computed Properties
    
    private var isOverdue: Bool {
        Date() > homework.dueDate.foundationDate
    }
    
    private var statusIcon: String {
        if !submissions.isEmpty {
            return "checkmark.circle.fill"
        } else if isOverdue {
            return "exclamationmark.triangle.fill"
        } else {
            return "circle"
        }
    }
    
    private var statusColor: Color {
        if !submissions.isEmpty {
            return .green
        } else if isOverdue {
            return .red
        } else {
            return .gray
        }
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
    
    private var dueText: String {
        let calendar = Calendar.current
        let now = Date()
        let dueDate = homework.dueDate.foundationDate
        
        if calendar.isDateInToday(dueDate) {
            return "Due today"
        } else if calendar.isDateInTomorrow(dueDate) {
            return "Due tomorrow"
        } else if isOverdue {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return "Due \(formatter.localizedString(for: dueDate, relativeTo: now))"
        } else {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return "Due \(formatter.localizedString(for: dueDate, relativeTo: now))"
        }
    }
    
    private func scoreColor(for submission: FullWorksheetSolution) -> Color {
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
}

// MARK: - Status Badge

struct StatusBadge1: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .cornerRadius(6)
    }
}

