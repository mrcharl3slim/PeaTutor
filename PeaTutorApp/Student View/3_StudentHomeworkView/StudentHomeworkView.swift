//
//  StudentHomeworkView.swift
//  PeaTutorApp
//
//  Sprint 5 Phase 2: Optional student homework dashboard
//  Shows all homework across all classes with filtering
//

import SwiftUI
import Amplify

struct StudentHomeworkView: View {
    @StateObject private var viewModel = StudentHomeworkViewModel()
    @State private var selectedFilter: HomeworkFilter = .all
    
    enum HomeworkFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case submitted = "Submitted"
        case overdue = "Overdue"
    }
    
    var body: some View {
        NavigationView {
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
                if viewModel.isLoading {
                    ProgressView("Loading homework...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredHomework.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredHomework, id: \.id) { item in
                                NavigationLink(destination: HomeworkDetailView(homework: item.homework)) {
                                    HomeworkDashboardCard(item: item)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Homework")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        Task {
                            await viewModel.loadHomework()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                await viewModel.loadHomework()
            }
        }
    }
    
    // MARK: - Filtered Homework
    
    private var filteredHomework: [HomeworkItem] {
        switch selectedFilter {
        case .all:
            return viewModel.allHomework
        case .pending:
            return viewModel.allHomework.filter { !$0.isSubmitted && !$0.isOverdue }
        case .submitted:
            return viewModel.allHomework.filter { $0.isSubmitted }
        case .overdue:
            return viewModel.allHomework.filter { $0.isOverdue && !$0.isSubmitted }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            emptyStateTitle,
            systemImage: emptyStateIcon,
            description: Text(emptyStateDescription)
        )
    }
    
    private var emptyStateTitle: String {
        switch selectedFilter {
        case .all: return "No Homework"
        case .pending: return "No Pending Homework"
        case .submitted: return "No Submitted Homework"
        case .overdue: return "No Overdue Homework"
        }
    }
    
    private var emptyStateIcon: String {
        switch selectedFilter {
        case .all: return "tray"
        case .pending: return "clock"
        case .submitted: return "checkmark.circle"
        case .overdue: return "exclamationmark.triangle"
        }
    }
    
    private var emptyStateDescription: String {
        switch selectedFilter {
        case .all: return "You don't have any homework assignments yet"
        case .pending: return "Great! You're all caught up"
        case .submitted: return "Submit your first homework to see it here"
        case .overdue: return "You don't have any overdue assignments"
        }
    }
}

// MARK: - View Model

@MainActor
class StudentHomeworkViewModel: ObservableObject {
    @Published var allHomework: [HomeworkItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let awsService = AWSService.shared
    private let homeworkService = HomeworkService.shared
    
    func loadHomework() async {
        isLoading = true
        defer { isLoading = false }
        
        guard let userId = awsService.currentUserId else { return }
        
        do {
            // 1. Get all classrooms the student is in
            let memberships = try await Amplify.DataStore.query(
                ClassroomMembership.self,
                where: ClassroomMembership.keys.studentId == userId
                    && ClassroomMembership.keys.status == MembershipStatus.approved.rawValue
            )
            
            var homeworkItems: [HomeworkItem] = []
            
            // 2. For each classroom, fetch homework
            for membership in memberships {
                guard let classroom = membership.classroom else { continue }
                
                let classroomHomework = try await homeworkService.fetchClassroomHomework(
                    classroomId: classroom.id,
                    publishedOnly: true
                )
                
                // 3. For each homework, check submission status
                for homework in classroomHomework {
                    let submissions = try await Amplify.DataStore.query(
                        FullWorksheetSolution.self,
                        where: FullWorksheetSolution.keys.homework.eq(homework.id)
                            && FullWorksheetSolution.keys.userId == userId
                    )
                    
                    let isSubmitted = !submissions.isEmpty
                    let isOverdue = homework.dueDate.foundationDate < Date()
                    let attemptCount = submissions.count
                    
                    let item = HomeworkItem(
                        id: homework.id,
                        homework: homework,
                        classroom: classroom,
                        isSubmitted: isSubmitted,
                        isOverdue: isOverdue,
                        attemptCount: attemptCount,
                        lastSubmissionDate: submissions.max(by: { $0.submittedAt < $1.submittedAt })?.submittedAt.foundationDate
                    )
                    
                    homeworkItems.append(item)
                }
            }
            
            // 4. Sort by due date (upcoming first, then past)
            homeworkItems.sort { item1, item2 in
                let now = Date()
                let date1 = item1.homework.dueDate.foundationDate
                let date2 = item2.homework.dueDate.foundationDate
                
                let future1 = date1 > now
                let future2 = date2 > now
                
                if future1 && !future2 {
                    return true // future items first
                } else if !future1 && future2 {
                    return false
                } else if future1 && future2 {
                    return date1 < date2 // upcoming sooner first
                } else {
                    return date1 > date2 // recent past first
                }
            }
            
            allHomework = homeworkItems
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to load homework: \(error)")
        }
    }
}

// MARK: - Homework Item

struct HomeworkItem: Identifiable {
    let id: String
    let homework: Homework
    let classroom: Classroom
    let isSubmitted: Bool
    let isOverdue: Bool
    let attemptCount: Int
    let lastSubmissionDate: Date?
}

// MARK: - Homework Dashboard Card

struct HomeworkDashboardCard: View {
    let item: HomeworkItem
    
    var body: some View {
        VStack(spacing: 0) {
            // Class Header
            HStack {
                Image(systemName: "building.2")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text(item.classroom.className)
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            
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
                    Text(item.homework.title)
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
                    .foregroundColor(item.isOverdue ? .red : .secondary)
                    
                    // Status badges
                    HStack(spacing: 8) {
                        // Submission status
                        StatusBadge(
                            text: statusText,
                            color: statusColor
                        )
                        
                        // Attempt count (if submitted)
                        if item.attemptCount > 0 {
                            StatusBadge(
                                text: "\(item.attemptCount) attempt\(item.attemptCount == 1 ? "" : "s")",
                                color: .purple
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
    
    private var statusIcon: String {
        if item.isSubmitted {
            return "checkmark.circle.fill"
        } else if item.isOverdue {
            return "exclamationmark.triangle.fill"
        } else {
            return "circle"
        }
    }
    
    private var statusColor: Color {
        if item.isSubmitted {
            return .green
        } else if item.isOverdue {
            return .red
        } else {
            return .gray
        }
    }
    
    private var statusText: String {
        if item.isSubmitted {
            return "Submitted"
        } else if item.isOverdue {
            return "Overdue"
        } else {
            return "Pending"
        }
    }
    
    private var dueText: String {
        let calendar = Calendar.current
        let now = Date()
        let dueDate = item.homework.dueDate.foundationDate
        
        if calendar.isDateInToday(dueDate) {
            return "Due today"
        } else if calendar.isDateInTomorrow(dueDate) {
            return "Due tomorrow"
        } else if item.isOverdue {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return "Due \(formatter.localizedString(for: dueDate, relativeTo: now))"
        } else {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return "Due \(formatter.localizedString(for: dueDate, relativeTo: now))"
        }
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
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
