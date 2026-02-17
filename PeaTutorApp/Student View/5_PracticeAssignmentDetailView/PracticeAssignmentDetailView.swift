//
//  PracticeAssignmentDetailView.swift
//  PeaTutorApp
//
//  View for students to view practice assignment details and start practice
//  Mirrors HomeworkDetailView structure for consistency
//

import SwiftUI
import Amplify

struct PracticeAssignmentDetailView: View {
    let assignment: PracticeAssignment
    
    @StateObject private var awsService = AWSService.shared
    @StateObject private var assignmentService = PracticeAssignmentService.shared
    
    @State private var problems: [PracticeProblem] = []
    @State private var assignerProfile: UserProfile?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingPracticeSession = false
    @State private var updatedAssignment: PracticeAssignment?
    
    // Use updated assignment if available, otherwise original
    private var currentAssignment: PracticeAssignment {
        updatedAssignment ?? assignment
    }
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading practice...")
            } else if let error = errorMessage {
                ContentUnavailableView(
                    "Error Loading Practice",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Assignment Header
                        assignmentHeaderCard
                        
                        // Status Badge
                        statusBadge
                        
                        // Curriculum Context
                        if !currentAssignment.curriculumCodesArray.isEmpty || !currentAssignment.targetConceptsArray.isEmpty {
                            curriculumContextCard
                        }
                        
                        // Problems Preview
                        problemsPreviewSection
                        
                        // Action Button
                        actionSection
                        
                        // Results (if completed)
                        if currentAssignment.statusEnum == .completed {
                            resultsSection
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(currentAssignment.title)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown error occurred")
        }
        .task {
            await loadAssignmentData()
        }
        .fullScreenCover(isPresented: $showingPracticeSession) {
            PracticeSessionView(
                problems: problems,
                child: nil,
                assignment: currentAssignment,
                onComplete: { completedAssignment in
                    updatedAssignment = completedAssignment
                }
            )
        }
    }
    
    // MARK: - Assignment Header Card
    
    private var assignmentHeaderCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Text(currentAssignment.title)
                .font(.title2.bold())
            
            // Description
            if let description = currentAssignment.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Metadata Grid
            VStack(spacing: 12) {
                // Due Date (if set)
                if let dueDate = currentAssignment.dueDate {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(currentAssignment.isOverdue ? .red : .orange)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Due Date")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatDueDate(dueDate.foundationDate))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        // Countdown
                        if let countdown = dueDateCountdown {
                            Text(countdown)
                                .font(.caption)
                                .foregroundColor(currentAssignment.isOverdue ? .red : .orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(currentAssignment.isOverdue ? Color.red.opacity(0.1) : Color.orange.opacity(0.1))
                                .cornerRadius(6)
                        }
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
                        Text(formatDate(currentAssignment.assignedDate.foundationDate))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                }
                
                // Assigned By
                HStack {
                    Image(systemName: assignerIcon)
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Assigned By")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(assignerDisplayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    // Role badge
                    Text(currentAssignment.assignedByRole.capitalized)
                        .font(.caption2)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(6)
                }
                
                // Problem Count
                HStack {
                    Image(systemName: "list.number")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Problems")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(currentAssignment.problemCount) problems")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                }
                
                // Source Type
                HStack {
                    Image(systemName: currentAssignment.sourceTypeIcon)
                        .foregroundColor(sourceTypeColor)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Source")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(currentAssignment.sourceTypeDisplayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
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
                Image(systemName: currentAssignment.statusIcon)
                    .foregroundColor(statusColor)
                Text(currentAssignment.statusDisplayText)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(statusColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(statusColor.opacity(0.15))
            .cornerRadius(20)
            
            Spacer()
            
            // Time spent (if started)
            if let timeSpent = currentAssignment.timeSpentSeconds, timeSpent > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                    Text(currentAssignment.timeSpentFormatted)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Curriculum Context Card
    
    private var curriculumContextCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "book.closed.fill")
                    .foregroundColor(.blue)
                Text("Curriculum Alignment")
                    .font(.headline)
            }
            
            // Grade Level
            if let gradeLevel = currentAssignment.curriculumGradeLevel {
                HStack {
                    Text("Grade Level:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(gradeLevel)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            // Curriculum Codes
            if !currentAssignment.curriculumCodesArray.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Curriculum Codes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    FlowLayoutDetail(spacing: 6) {
                        ForEach(currentAssignment.curriculumCodesArray, id: \.self) { code in
                            Text(code)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                        }
                    }
                }
            }
            
            // Target Concepts
            if !currentAssignment.targetConceptsArray.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Concepts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    FlowLayoutDetail(spacing: 6) {
                        ForEach(currentAssignment.targetConceptsArray, id: \.self) { concept in
                            Text(concept)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Problems Preview Section
    
    private var problemsPreviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("Practice Problems")
                    .font(.headline)
                
                Spacer()
                
                Text("\(problems.count) problems")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if problems.isEmpty {
                Text("Loading problems...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(problems.prefix(3), id: \.id) { problem in
                        ProblemPreviewCard(problem: problem)
                    }
                    
                    if problems.count > 3 {
                        Text("... and \(problems.count - 3) more problems")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                            .padding(.top, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Action Section
    
    private var actionSection: some View {
        VStack(spacing: 12) {
            Button(action: startPractice) {
                HStack {
                    Image(systemName: actionButtonIcon)
                    Text(actionButtonText)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(actionButtonColor)
                .cornerRadius(16)
            }
            .disabled(problems.isEmpty)
            
            // Tips for students
            if currentAssignment.statusEnum == .pending {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    
                    Text("**Tip:** Take your time and use the hints if you get stuck!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Results Section
    
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.green)
                Text("Results")
                    .font(.headline)
            }
            
            // Score
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(currentAssignment.correctCount ?? 0)")
                            .font(.title.bold())
                            .foregroundColor(.green)
                        Text("/")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("\(currentAssignment.totalAttempted ?? 0)")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Percentage
                ZStack {
                    Circle()
                        .stroke(Color.green.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat((currentAssignment.score ?? 0) / 100))
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    Text(currentAssignment.scorePercentageString)
                        .font(.headline)
                        .foregroundColor(.green)
                }
            }
            
            Divider()
            
            // Time and completion details
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time Spent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(currentAssignment.timeSpentFormatted)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                if let completedAt = currentAssignment.completedAt {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Completed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatDate(completedAt.foundationDate))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.green.opacity(0.1), Color.mint.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.3), lineWidth: 2)
        )
    }
    
    // MARK: - Computed Properties
    
    private var statusColor: Color {
        switch currentAssignment.statusEnum {
        case .pending: return .gray
        case .inProgress: return .orange
        case .completed: return .green
        }
    }
    
    private var sourceTypeColor: Color {
        switch currentAssignment.sourceTypeEnum {
        case .prerequisiteGap: return .orange
        case .recommended: return .yellow
        case .weakArea: return .red
        case .topic: return .blue
        case .selfPractice: return .purple
        }
    }
    
    private var assignerIcon: String {
        switch currentAssignment.assignerRoleEnum {
        case .teacher: return "person.fill.badge.plus"
        case .parent: return "figure.2.and.child.holdinghands"
        case .student: return "person.fill"
        }
    }
    
    private var assignerDisplayName: String {
        if currentAssignment.isSelfAssigned {
            return "Self"
        }
        return assignerProfile?.displayName ?? "Unknown"
    }
    
    private var actionButtonText: String {
        switch currentAssignment.statusEnum {
        case .pending: return "Start Practice"
        case .inProgress: return "Continue Practice"
        case .completed: return "Review Practice"
        }
    }
    
    private var actionButtonIcon: String {
        switch currentAssignment.statusEnum {
        case .pending: return "play.fill"
        case .inProgress: return "arrow.right.circle.fill"
        case .completed: return "arrow.counterclockwise"
        }
    }
    
    private var actionButtonColor: Color {
        switch currentAssignment.statusEnum {
        case .pending: return .blue
        case .inProgress: return .orange
        case .completed: return .green
        }
    }
    
    private var dueDateCountdown: String? {
        assignmentService.timeRemaining(for: currentAssignment)
    }
    
    // MARK: - Actions
    
    private func loadAssignmentData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load problems
            problems = try await assignmentService.fetchProblemsForAssignment(assignment)
            
            // Load assigner profile (if not self)
            if !assignment.isSelfAssigned {
                let profiles = try await Amplify.DataStore.query(UserProfile.self)
                assignerProfile = profiles.first { $0.userId == assignment.assignedByUserId }
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func startPractice() {
        showingPracticeSession = true
    }
    
    // MARK: - Formatters
    
    private func formatDueDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Problem Preview Card

struct ProblemPreviewCard: View {
    let problem: PracticeProblem
    
    var body: some View {
        HStack(spacing: 12) {
            // Concept badge
            Text(problem.concept)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue)
                .cornerRadius(4)
            
            // Problem type
            Text(problem.questionType)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Difficulty indicator
            HStack(spacing: 2) {
                ForEach(0..<difficultyLevel, id: \.self) { _ in
                    Circle()
                        .fill(difficultyColor)
                        .frame(width: 6, height: 6)
                }
                ForEach(0..<(3 - difficultyLevel), id: \.self) { _ in
                    Circle()
                        .stroke(difficultyColor.opacity(0.3), lineWidth: 1)
                        .frame(width: 6, height: 6)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    private var difficultyLevel: Int {
        switch problem.difficultyLevel.lowercased() {
        case "easier", "easy": return 1
        case "similar", "medium": return 2
        case "harder", "hard": return 3
        default: return 2
        }
    }
    
    private var difficultyColor: Color {
        switch problem.difficultyLevel.lowercased() {
        case "easier", "easy": return .green
        case "similar", "medium": return .orange
        case "harder", "hard": return .red
        default: return .gray
        }
    }
}

// MARK: - Flow Layout

struct FlowLayoutDetail: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResultDetail(in: proposal.width ?? 0, spacing: spacing, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResultDetail(in: bounds.width, spacing: spacing, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                     y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResultDetail {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, spacing: CGFloat, subviews: Subviews) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x)
            }
            
            self.size.height = y + rowHeight
        }
    }
}
