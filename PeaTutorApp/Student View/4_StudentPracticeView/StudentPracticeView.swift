//
//  StudentPracticeView.swift
//  PeaTutorApp
//
//  Sprint 7.4: AI-Powered Practice Generation
//  Student-facing practice hub for self-directed learning
//
//  Updated: Added assigned practice section at top
//

import SwiftUI
import Amplify

struct StudentPracticeView: View {
    @StateObject private var awsService = AWSService.shared
    @StateObject private var queryService = AnalyticsQueryService.shared
    @StateObject private var generationService = PracticeGenerationService.shared
    @StateObject private var assignmentService = PracticeAssignmentService.shared
    
    @State private var weakConcepts: [ConceptMastery] = []
    @State private var allConcepts: [ConceptMastery] = []
    @State private var assignments: [PracticeAssignment] = []
    @State private var isLoading = false
    @State private var showingPracticeSession = false
    @State private var generatedProblems: [PracticeProblem] = []
    @State private var selectedAssignment: PracticeAssignment?
    @State private var selectedDifficulty: PracticeDifficulty = .similar
    @State private var errorMessage: String?
    @State private var selectedTab: PracticeTab = .assigned
    
    @Environment(\.dismiss) private var dismiss
    
    enum PracticeTab: String, CaseIterable {
        case assigned = "Assigned"
        case explore = "Explore"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Practice Tab", selection: $selectedTab) {
                    ForEach(PracticeTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        if isLoading {
                            loadingView
                        } else {
                            switch selectedTab {
                            case .assigned:
                                assignedPracticeContent
                            case .explore:
                                explorePracticeContent
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Practice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .fullScreenCover(isPresented: $showingPracticeSession) {
                if let profile = awsService.currentUserProfile {
                    PracticeSessionView(
                        problems: generatedProblems,
                        child: profile,
                        assignment: selectedAssignment,
                        onComplete: { completedAssignment in
                            // Refresh assignments after completion
                            Task {
                                await loadAssignments()
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Assigned Practice Content
    
    private var assignedPracticeContent: some View {
        VStack(spacing: 24) {
            // Pending Assignments
            let pendingAssignments = assignments.filter { $0.statusEnum != .completed }
            if !pendingAssignments.isEmpty {
                pendingAssignmentsSection(assignments: pendingAssignments)
            }
            
            // Completed Assignments
            let completedAssignments = assignments.filter { $0.statusEnum == .completed }
            if !completedAssignments.isEmpty {
                completedAssignmentsSection(assignments: completedAssignments)
            }
            
            // No assignments state
            if assignments.isEmpty {
                noAssignmentsView
            }
        }
    }
    
    // MARK: - Pending Assignments Section
    
    private func pendingAssignmentsSection(assignments: [PracticeAssignment]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tray.full.fill")
                    .foregroundColor(.blue)
                Text("Pending Practice")
                    .font(.headline)
                
                Spacer()
                
                Text("\(assignments.count)")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            
            ForEach(assignments, id: \.id) { assignment in
                PracticeAssignmentCard(
                    assignment: assignment,
                    onStart: {
                        startAssignment(assignment)
                    }
                )
            }
        }
    }
    
    // MARK: - Completed Assignments Section
    
    private func completedAssignmentsSection(assignments: [PracticeAssignment]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Completed")
                    .font(.headline)
                
                Spacer()
                
                Text("\(assignments.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ForEach(assignments.prefix(5), id: \.id) { assignment in
                CompletedAssignmentCard(assignment: assignment)
            }
            
            if assignments.count > 5 {
                NavigationLink {
                    AllCompletedAssignmentsView(assignments: assignments)
                } label: {
                    Text("View All \(assignments.count) Completed")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    // MARK: - No Assignments View
    
    private var noAssignmentsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No Practice Assigned Yet")
                .font(.headline)
            
            Text("When your teacher or parent assigns practice, it will appear here. In the meantime, explore practice topics on your own!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { selectedTab = .explore }) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Explore Practice")
                }
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Explore Practice Content (existing content)
    
    private var explorePracticeContent: some View {
        VStack(spacing: 24) {
            // Header
            headerSection
            
            // Quick Practice Options
            quickPracticeSection
            
            // Weak Areas (if any)
            if !weakConcepts.isEmpty {
                weakAreasSection
            }
            
            // All Concepts
            if !allConcepts.isEmpty {
                allConceptsSection
            }
            
            // No Data State
            if allConcepts.isEmpty && !isLoading {
                noDataView
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.2), .blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            Text("Extra Practice")
                .font(.title2.bold())
            
            Text("Sharpen your skills with AI-generated problems")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading your progress...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
    
    // MARK: - No Data View
    
    private var noDataView: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("Complete Some Homework First")
                .font(.headline)
            
            Text("After you complete homework assignments, you'll see your concepts here and can generate practice problems!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Quick Practice Section
    
    private var quickPracticeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Start")
                .font(.headline)
            
            Text("Choose a difficulty and start practicing right away")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                ForEach(PracticeDifficulty.allCases) { difficulty in
                    QuickStartDifficultyCard(
                        difficulty: difficulty,
                        isLoading: generationService.isGenerating && selectedDifficulty == difficulty
                    ) {
                        selectedDifficulty = difficulty
                        generateQuickPractice()
                    }
                }
            }
            
            if generationService.isGenerating {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Generating problems...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Weak Areas Section
    
    private var weakAreasSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.orange)
                Text("Focus Areas")
                    .font(.headline)
                
                Spacer()
                
                Button(action: practiceAllWeakAreas) {
                    Text("Practice All")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange)
                        .cornerRadius(8)
                }
            }
            
            Text("These concepts need more practice")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ForEach(weakConcepts.prefix(3), id: \.id) { concept in
                StudentWeakConceptRow(concept: concept) {
                    generatePracticeForConcept(concept.concept)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - All Concepts Section
    
    private var allConceptsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Concepts")
                .font(.headline)
            
            Text("Practice any concept you've learned")
                .font(.caption)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(allConcepts, id: \.id) { concept in
                    ConceptPracticeCard(concept: concept) {
                        generatePracticeForConcept(concept.concept)
                    }
                }
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadData() async {
        isLoading = true
        
        await loadAssignments()
        await loadMasteryData()
        
        isLoading = false
    }
    
    private func loadAssignments() async {
        guard let userId = awsService.currentUserId else { return }
        
        do {
            assignments = try await assignmentService.fetchStudentAssignments(studentId: userId)
        } catch {
            print("⚠️ Failed to load assignments: \(error)")
        }
    }
    
    private func loadMasteryData() async {
            guard let userId = awsService.currentUserId else { return }
            
            do {
                allConcepts = try await queryService.fetchConceptMastery(studentId: userId, classroomId: nil)
                weakConcepts = allConcepts.filter { $0.masteryPercentage < 70 }
                    .sorted { $0.masteryPercentage < $1.masteryPercentage }
            } catch {
                print("⚠️ Failed to load mastery data: \(error)")
            }
        }
    
    // MARK: - Actions
    
    private func startAssignment(_ assignment: PracticeAssignment) {
        Task {
            do {
                // Fetch problems for the assignment
                let problems = try await assignmentService.fetchProblemsForAssignment(assignment)
                
                // Start the assignment (mark as in progress)
                let startedAssignment = try await assignmentService.startAssignment(assignment)
                
                selectedAssignment = startedAssignment
                generatedProblems = problems
                showingPracticeSession = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func generateQuickPractice() {
        guard let userId = awsService.currentUserProfile?.userId else { return }
        
        Task {
            do {
                selectedAssignment = nil // No assignment for quick practice
                
                if !weakConcepts.isEmpty {
                    // Prioritize weak concepts
                    generatedProblems = try await generationService.generateForWeakAreas(
                        studentId: userId,
                        classroomId: nil,
                        count: 10,
                        userId: userId
                    )
                } else if !allConcepts.isEmpty {
                    // Generate for all concepts
                    let concepts = allConcepts.prefix(3).map { $0.concept }
                    generatedProblems = try await generationService.generateForConcepts(
                        concepts: Array(concepts),
                        difficulty: selectedDifficulty,
                        count: 10,
                        userId: userId
                    )
                } else {
                    errorMessage = "Complete some homework first to generate practice!"
                    return
                }
                showingPracticeSession = true
            } catch {
                print("⚠️ Failed to generate practice: \(error)")
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func practiceAllWeakAreas() {
        guard let userId = awsService.currentUserProfile?.userId else { return }
        
        Task {
            do {
                selectedAssignment = nil
                generatedProblems = try await generationService.generateForWeakAreas(
                    studentId: userId,
                    classroomId: nil,
                    count: 10,
                    userId: userId
                )
                showingPracticeSession = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func generatePracticeForConcept(_ concept: String) {
        guard let userId = awsService.currentUserProfile?.userId else { return }
        
        Task {
            do {
                selectedAssignment = nil
                generatedProblems = try await generationService.generateForConcept(
                    concept: concept,
                    difficulty: selectedDifficulty,
                    count: 10,
                    sourceWorksheetId: nil,
                    gradeLevel: nil,
                    userId: userId
                )
                showingPracticeSession = true
            } catch {
                print("⚠️ Failed to generate practice: \(error)")
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Practice Assignment Card

struct PracticeAssignmentCard: View {
    let assignment: PracticeAssignment
    let onStart: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack {
                // Source type badge
                HStack(spacing: 4) {
                    Image(systemName: assignment.sourceTypeIcon)
                        .font(.caption)
                    Text(assignment.sourceTypeDisplayName)
                        .font(.caption)
                }
                .foregroundColor(sourceTypeColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(sourceTypeColor.opacity(0.1))
                .cornerRadius(6)
                
                Spacer()
                
                // Status
                HStack(spacing: 4) {
                    Image(systemName: assignment.statusIcon)
                    Text(assignment.statusDisplayText)
                }
                .font(.caption)
                .foregroundColor(statusColor)
            }
            
            // Title
            Text(assignment.title)
                .font(.headline)
            
            // Description (if any)
            if let description = assignment.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // Metadata row
            HStack {
                // Assigned by
                HStack(spacing: 4) {
                    Image(systemName: assignerIcon)
                        .font(.caption2)
                    Text(assignment.isSelfAssigned ? "Self" : assignment.assignedByRole.capitalized)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                // Problem count
                Text("\(assignment.problemCount) problems")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let dueDate = assignment.dueDate {
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    // Due date
                    HStack(spacing: 2) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(formatDueDate(dueDate.foundationDate))
                            .font(.caption)
                    }
                    .foregroundColor(assignment.isOverdue ? .red : .orange)
                }
                
                Spacer()
            }
            
            // Curriculum codes (if any)
            if !assignment.curriculumCodesArray.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(assignment.curriculumCodesArray.prefix(3), id: \.self) { code in
                            Text(code)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                        
                        if assignment.curriculumCodesArray.count > 3 {
                            Text("+\(assignment.curriculumCodesArray.count - 3)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Start button
            Button(action: onStart) {
                HStack {
                    Image(systemName: assignment.statusEnum == .inProgress ? "play.fill" : "play.circle.fill")
                    Text(assignment.statusEnum == .inProgress ? "Continue" : "Start Practice")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.blue)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    private var sourceTypeColor: Color {
        switch assignment.sourceTypeEnum {
        case .prerequisiteGap: return .orange
        case .recommended: return .yellow
        case .weakArea: return .red
        case .topic: return .blue
        case .selfPractice: return .purple
        }
    }
    
    private var statusColor: Color {
        switch assignment.statusEnum {
        case .pending: return .gray
        case .inProgress: return .orange
        case .completed: return .green
        }
    }
    
    private var assignerIcon: String {
        switch assignment.assignerRoleEnum {
        case .teacher: return "person.fill.badge.plus"
        case .parent: return "figure.2.and.child.holdinghands"
        case .student: return "person.fill"
        }
    }
    
    private func formatDueDate(_ date: Date) -> String {
        let now = Date()
        let diff = date.timeIntervalSince(now)
        
        if diff < 0 {
            return "Overdue"
        } else if diff < 3600 {
            return "< 1 hour"
        } else if diff < 86400 {
            return "\(Int(diff / 3600))h left"
        } else {
            return "\(Int(diff / 86400))d left"
        }
    }
}

// MARK: - Completed Assignment Card

struct CompletedAssignmentCard: View {
    let assignment: PracticeAssignment
    
    var body: some View {
        HStack(spacing: 12) {
            // Score circle
            ZStack {
                Circle()
                    .stroke(Color.green.opacity(0.3), lineWidth: 4)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .trim(from: 0, to: CGFloat((assignment.score ?? 0) / 100))
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                
                Text(assignment.scorePercentageString)
                    .font(.caption.bold())
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(assignment.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text("\(assignment.correctCount ?? 0)/\(assignment.totalAttempted ?? 0)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(assignment.timeSpentFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let completedAt = assignment.completedAt {
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(formatDate(completedAt.foundationDate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - All Completed Assignments View

struct AllCompletedAssignmentsView: View {
    let assignments: [PracticeAssignment]
    
    var body: some View {
        List {
            ForEach(assignments, id: \.id) { assignment in
                CompletedAssignmentCard(assignment: assignment)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle())
        .navigationTitle("Completed Practice")
    }
}

// MARK: - Quick Start Difficulty Card

struct QuickStartDifficultyCard: View {
    let difficulty: PracticeDifficulty
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .frame(height: 32)
                } else {
                    Text(difficulty.icon)
                        .font(.system(size: 28))
                }
                
                Text(difficulty.displayName)
                    .font(.caption.bold())
                    .foregroundColor(.primary)
                
                Text(difficulty.shortDescription)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(difficulty.color.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(difficulty.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
    }
}

// MARK: - Student Weak Concept Row

struct StudentWeakConceptRow: View {
    let concept: ConceptMastery
    let onPractice: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Mastery Circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                    .frame(width: 36, height: 36)
                
                Circle()
                    .trim(from: 0, to: concept.masteryPercentage / 100)
                    .stroke(masteryColor, lineWidth: 3)
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(concept.masteryPercentage))")
                    .font(.caption2.bold())
                    .foregroundColor(masteryColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(concept.concept)
                    .font(.subheadline.bold())
                
                Text(trendText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onPractice) {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.caption)
                    Text("Practice")
                        .font(.caption.bold())
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var masteryColor: Color {
        if concept.masteryPercentage >= 60 { return .yellow }
        if concept.masteryPercentage >= 40 { return .orange }
        return .red
    }
    
    private var trendText: String {
        switch concept.trend {
        case "improving": return "📈 Getting better!"
        case "declining": return "📉 Needs attention"
        default: return "→ \(concept.totalAttempts) attempts"
        }
    }
}

// MARK: - Concept Practice Card

struct ConceptPracticeCard: View {
    let concept: ConceptMastery
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(concept.concept)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                            .cornerRadius(3)
                        
                        Rectangle()
                            .fill(masteryColor)
                            .frame(width: geometry.size.width * (concept.masteryPercentage / 100), height: 6)
                            .cornerRadius(3)
                    }
                }
                .frame(height: 6)
                
                HStack {
                    Text("\(Int(concept.masteryPercentage))%")
                        .font(.caption)
                        .foregroundColor(masteryColor)
                    
                    Spacer()
                    
                    Image(systemName: "play.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var masteryColor: Color {
        if concept.masteryPercentage >= 80 { return .green }
        if concept.masteryPercentage >= 60 { return .yellow }
        return .orange
    }
}
