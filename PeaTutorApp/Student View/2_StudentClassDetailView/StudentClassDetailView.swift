//
//  RefinedStudentClassDetailView.swift
//  PeaTutorApp
//
//  Sprint 8: Refined Student Class Detail View
//  Tabbed interface: Homework | Practice | Worksheets
//

import SwiftUI
import Amplify

struct StudentClassDetailView: View {
    let classroom: Classroom
    
    @StateObject private var awsService = AWSService.shared
    @StateObject private var homeworkService = HomeworkService.shared
    
    // Tab Selection
    @State private var selectedTab: ClassTab = .curriculum
    
    // Data
    @State private var homework: [HomeworkWithStatus] = []
    @State private var worksheets: [Worksheet] = []
    @State private var concepts: [ConceptMastery] = []
    
    // UI State
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showLeaveConfirmation = false
    
    enum ClassTab: String, CaseIterable {
        case curriculum = "Curriculum"
        case practice = "Practice"
        //case homework = "Homework"
        //case worksheets = "Worksheets"
        
        var icon: String {
            switch self {
            case .curriculum: return "book.closed.fill"
            case .practice: return "sparkles"
            //case .homework: return "doc.text.fill"
            // case .worksheets: return "doc.fill"
            }
        }
    }
    
    // Color based on classroom
    private var classColor: Color {
        let colors: [Color] = [.blue, .green, .purple, .orange, .pink]
        let hash = classroom.id.hashValue
        return colors[abs(hash) % colors.count]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header with Tabs
            headerWithTabs
            
            // Tab Content
            Group {
                if isLoading {
                    loadingView
                } else {
                    tabContent
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(classroom.className)
                    .font(.headline)
            }
            
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: refreshData) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: { showLeaveConfirmation = true }) {
                        Label("Leave Class", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Leave Class", isPresented: $showLeaveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Leave", role: .destructive) {
                Task { await leaveClass() }
            }
        } message: {
            Text("Are you sure you want to leave \(classroom.className)?")
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .task {
            await loadAllData()
        }
    }
    
    // MARK: - Header with Tabs
    
    private var headerWithTabs: some View {
        VStack(spacing: 0) {
            // Class Info Bar
            HStack(spacing: 12) {
                // Class Icon
                ZStack {
                    Circle()
                        .fill(classColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "book.fill")
                        .font(.title3)
                        .foregroundColor(classColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    if let subject = classroom.subject {
                        Text(subject)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    if let gradeLevel = classroom.gradeLevel {
                        Text(gradeLevel)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Quick Stats
                HStack(spacing: 16) {
                    VStack(spacing: 2) {
                        Text("\(pendingCount)")
                            .font(.headline.bold())
                            .foregroundColor(pendingCount > 0 ? .orange : .green)
                        Text("Due")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 2) {
                        Text("\(completedCount)")
                            .font(.headline.bold())
                            .foregroundColor(.green)
                        Text("Done")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            
            // Tab Bar
            HStack(spacing: 4) {
                ForEach(ClassTab.allCases, id: \.self) { tab in
                    TabButton2(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        count: countForTab(tab),
                        color: classColor
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))
        }
    }
    
    // MARK: - Tab Content
    
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
            
        case .curriculum:
            CurriculumTabView(
                classroom: classroom,
                classColor: classColor
            )
        case .practice:
            PracticeTabView(
                concepts: concepts,
                classroom: classroom,
                classColor: classColor
            )
        /*case .homework:
            HomeworkTabView(
                homework: homework,
                classColor: classColor
            )
            
        case .worksheets:
            WorksheetsTabView(
                worksheets: worksheets,
                classroom: classroom,
                classColor: classColor
            )*/
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Computed Properties
    
    private var pendingCount: Int {
        homework.filter { !$0.isSubmitted }.count
    }
    
    private var completedCount: Int {
        homework.filter { $0.isSubmitted }.count
    }
    
    private func countForTab(_ tab: ClassTab) -> Int {
        switch tab {
        case .curriculum: return 0
        //case .homework: return homework.count
        case .practice: return concepts.count
        //case .worksheets: return worksheets.count
        }
    }
    
    // MARK: - Data Loading
    
    private func loadAllData() async {
        isLoading = true
        defer { isLoading = false }
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await loadHomework() }
            group.addTask { await loadWorksheets() }
            group.addTask { await loadConcepts() }
        }
    }
    
    private func loadHomework() async {
        guard let userId = awsService.currentUserId else { return }
        
        do {
            let fetchedHomework = try await homeworkService.fetchClassroomHomework(
                classroomId: classroom.id,
                publishedOnly: true
            )
            
            var homeworkWithStatus: [HomeworkWithStatus] = []
            
            for hw in fetchedHomework {
                let submissions = try await Amplify.DataStore.query(
                    FullWorksheetSolution.self,
                    where: FullWorksheetSolution.keys.homework.eq(hw.id)
                        && FullWorksheetSolution.keys.userId == userId
                )
                
                let isSubmitted = !submissions.isEmpty
                let isOverdue = hw.dueDate.foundationDate < Date()
                let latestScore = submissions.map { $0.overallScore }.max()
                
                homeworkWithStatus.append(HomeworkWithStatus(
                    homework: hw,
                    isSubmitted: isSubmitted,
                    isOverdue: isOverdue,
                    attemptCount: submissions.count,
                    latestScore: latestScore
                ))
            }
            
            // Sort: pending first (by due date), then completed
            homeworkWithStatus.sort { h1, h2 in
                if h1.isSubmitted != h2.isSubmitted {
                    return !h1.isSubmitted // Pending first
                }
                return h1.homework.dueDate < h2.homework.dueDate
            }
            
            await MainActor.run {
                self.homework = homeworkWithStatus
            }
        } catch {
            print("âš ï¸ Failed to load homework: \(error)")
        }
    }
    
    private func loadWorksheets() async {
        guard let userId = awsService.currentUserId else { return }
        
        do {
            // For now, load all user worksheets
            // In future, can filter by classroom if worksheets have classroom association
            let fetchedWorksheets = try await Amplify.DataStore.query(
                Worksheet.self,
                where: Worksheet.keys.userId == userId
            )
            
            await MainActor.run {
                self.worksheets = fetchedWorksheets.sorted { $0.uploadedAt > $1.uploadedAt }
            }
        } catch {
            print("âš ï¸ Failed to load worksheets: \(error)")
        }
    }
    
    private func loadConcepts() async {
        guard let userId = awsService.currentUserId else { return }
        
        do {
            let fetchedConcepts = try await Amplify.DataStore.query(
                ConceptMastery.self,
                where: ConceptMastery.keys.studentId == userId
                    && ConceptMastery.keys.classroomId == classroom.id
            )
            
            await MainActor.run {
                // Sort by mastery (lowest first - needs most practice)
                self.concepts = fetchedConcepts.sorted { $0.masteryPercentage < $1.masteryPercentage }
            }
        } catch {
            print("âš ï¸ Failed to load concepts: \(error)")
        }
    }
    
    private func refreshData() {
        Task {
            await loadAllData()
        }
    }
    
    private func leaveClass() async {
        guard let userId = awsService.currentUserId else { return }
        
        do {
            let memberships = try await Amplify.DataStore.query(
                ClassroomMembership.self,
                where: ClassroomMembership.keys.classroom.eq(classroom.id)
                    && ClassroomMembership.keys.studentId == userId
            )
            
            if let membership = memberships.first {
                try await Amplify.DataStore.delete(membership)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Homework With Status Model

struct HomeworkWithStatus: Identifiable {
    let homework: Homework
    let isSubmitted: Bool
    let isOverdue: Bool
    let attemptCount: Int
    let latestScore: Int?
    
    var id: String { homework.id }
    
    var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: homework.dueDate.foundationDate).day ?? 0
    }
}

// MARK: - Tab Button

private struct TabButton2: View {
    let tab: StudentClassDetailView.ClassTab
    let isSelected: Bool
    let count: Int
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.caption)
                
                Text(tab.rawValue)
                    .font(.subheadline.weight(.medium))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2.bold())
                        .foregroundColor(isSelected ? .white : color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? color.opacity(0.3) : color.opacity(0.15))
                        )
                }
            }
            .foregroundColor(isSelected ? color : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? color.opacity(0.15) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Curriculum Tab View
private struct CurriculumTabView: View {
    let classroom: Classroom
    let classColor: Color
    
    @StateObject private var awsService = AWSService.shared
    @State private var userProfile: UserProfile?
    
    var body: some View {
        if let userId = awsService.currentUserId {
            StudentCurriculumProgressView(
                studentId: userId,
                studentName: userProfile?.displayName ?? "Student",
                classroomId: classroom.id,
                gradeLevel: classroom.gradeLevel ?? "Primary 1"
            )
            .task {
                await loadUserProfile()
            }
        } else {
            Text("Please sign in to view curriculum")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
        }
    }
    
    // Load user profile for student name
    private func loadUserProfile() async {
        guard let userId = awsService.currentUserId else { return }
        
        do {
            userProfile = try await Amplify.DataStore.query(
                UserProfile.self,
                where: UserProfile.keys.id == userId
            ).first
        } catch {
            print("Error loading user profile: \(error)")
        }
    }
}

// MARK: - Supporting Views for Curriculum Tab

private struct StatRow: View {
    let icon: String
    let color: Color
    let value: Int
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text("\(value)")
                .font(.subheadline.bold())
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

private struct StrandProgressRow2: View {
    let name: String
    let code: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(.subheadline)
                
                Spacer()
                
                Text("\(Int(progress))%")
                    .font(.subheadline.bold())
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(progress / 100))
                }
            }
            .frame(height: 8)
        }
    }
}

private struct TopicStatCard: View {
    let value: Int
    let total: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                Text("\(value)")
                    .font(.title2.bold())
                    .foregroundColor(color)
                
                Text("/\(total)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Homework Tab View

private struct HomeworkTabView: View {
    let homework: [HomeworkWithStatus]
    let classColor: Color
    
    private var pendingHomework: [HomeworkWithStatus] {
        homework.filter { !$0.isSubmitted }
    }
    
    private var completedHomework: [HomeworkWithStatus] {
        homework.filter { $0.isSubmitted }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Pending Section
                if !pendingHomework.isEmpty {
                    HomeworkSection(
                        title: "Due Soon",
                        icon: "clock.fill",
                        iconColor: .orange,
                        items: pendingHomework,
                        isPending: true
                    )
                }
                
                // Completed Section
                if !completedHomework.isEmpty {
                    HomeworkSection(
                        title: "Completed",
                        icon: "checkmark.circle.fill",
                        iconColor: .green,
                        items: completedHomework,
                        isPending: false
                    )
                }
                
                // Empty State
                if homework.isEmpty {
                    EmptyTabView(
                        icon: "doc.text",
                        title: "No Homework Yet",
                        message: "Your teacher hasn't assigned any homework for this class yet.",
                        color: classColor
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Homework Section

private struct HomeworkSection: View {
    let title: String
    let icon: String
    let iconColor: Color
    let items: [HomeworkWithStatus]
    let isPending: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.headline)
                
                Text("\(items.count)")
                    .font(.caption.bold())
                    .foregroundColor(iconColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(iconColor.opacity(0.15))
                    .cornerRadius(8)
            }
            
            // Homework Cards
            VStack(spacing: 10) {
                ForEach(items) { item in
                    NavigationLink {
                        HomeworkDetailView(homework: item.homework)
                    } label: {
                        HomeworkCard(item: item, isPending: isPending)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Homework Card

private struct HomeworkCard: View {
    let item: HomeworkWithStatus
    let isPending: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            // Status Icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: statusIcon)
                    .font(.title3)
                    .foregroundColor(statusColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.homework.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                HStack(spacing: 12) {
                    // Due date
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(dueDateText)
                            .font(.caption)
                    }
                    .foregroundColor(item.isOverdue && isPending ? .red : .secondary)
                    
                    // Score (if completed)
                    if let score = item.latestScore {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                            Text("\(score)%")
                                .font(.caption.bold())
                        }
                        .foregroundColor(scoreColor(Double(score)))
                    }
                    
                    // Attempt count
                    if item.attemptCount > 0 {
                        Text("\(item.attemptCount) attempt\(item.attemptCount == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.03), radius: 4, y: 2)
    }
    
    private var statusIcon: String {
        if item.isSubmitted {
            return "checkmark.circle.fill"
        } else if item.isOverdue {
            return "exclamationmark.triangle.fill"
        } else if item.daysUntilDue <= 1 {
            return "clock.badge.exclamationmark.fill"
        } else {
            return "circle"
        }
    }
    
    private var statusColor: Color {
        if item.isSubmitted {
            return .green
        } else if item.isOverdue {
            return .red
        } else if item.daysUntilDue <= 1 {
            return .orange
        } else {
            return .gray
        }
    }
    
    private var dueDateText: String {
        let dueDate = item.homework.dueDate.foundationDate
        let calendar = Calendar.current
        
        if calendar.isDateInToday(dueDate) {
            return "Due today"
        } else if calendar.isDateInTomorrow(dueDate) {
            return "Due tomorrow"
        } else if item.isOverdue {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return "Due \(formatter.localizedString(for: dueDate, relativeTo: Date()))"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "Due \(formatter.string(from: dueDate))"
        }
    }
    
    private func scoreColor(_ score: Double) -> Color {
        if score >= 80 { return .green }
        if score >= 60 { return .orange }
        return .red
    }
}

// MARK: - Practice Tab View

private struct PracticeTabView: View {
    let concepts: [ConceptMastery]
    let classroom: Classroom
    let classColor: Color
    
    @State private var showingPracticeSession = false
    @State private var selectedConcept: ConceptMastery?
    @StateObject private var generationService = PracticeGenerationService.shared
    @StateObject private var awsService = AWSService.shared
    @State private var generatedProblems: [PracticeProblem] = []
    
    // Assigned Practice
    @State private var assignedPractice: [PracticeAssignment] = []
    @State private var isLoadingAssignments = false
    @State private var selectedAssignment: PracticeAssignment?
    @State private var showingAssignmentDetail = false
    @State private var observationTask: Task<Void, Never>?
    @State private var isSyncing = false
    
    private var weakConcepts: [ConceptMastery] {
        concepts.filter { $0.masteryPercentage < 60 }
    }
    
    private var pendingAssignments: [PracticeAssignment] {
        assignedPractice.filter { $0.statusEnum != .completed }
    }
    
    private var completedAssignments: [PracticeAssignment] {
        assignedPractice.filter { $0.statusEnum == .completed }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Assigned Practice Section (from teachers/parents)
                if !assignedPractice.isEmpty || isLoadingAssignments {
                    assignedPracticeSection
                }
                
                // AI Practice Generator Card
                //aiPracticeCard
                
                // Weak Areas (if any)
                /*if !weakConcepts.isEmpty {
                    weakAreasSection
                }
                
                // All Concepts
                if !concepts.isEmpty {
                    allConceptsSection
                }
                
                // Empty State
                if concepts.isEmpty && assignedPractice.isEmpty && !isLoadingAssignments {
                    EmptyTabView(
                        icon: "sparkles",
                        title: "No Practice Data Yet",
                        message: "Complete homework assignments to unlock personalized practice recommendations.",
                        color: classColor
                    )
                }*/
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            startObservingAssignments()
        }
        .onDisappear {
            observationTask?.cancel()
            observationTask = nil
        }
        .refreshable {
            await refreshAssignmentsFromCloud()
        }
        .fullScreenCover(isPresented: $showingPracticeSession) {
            if let profile = awsService.currentUserProfile {
                PracticeSessionView(
                    problems: generatedProblems,
                    child: profile
                )
            }
        }
        .sheet(isPresented: $showingAssignmentDetail) {
            if let assignment = selectedAssignment {
                NavigationStack {
                    PracticeAssignmentDetailView(assignment: assignment)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    showingAssignmentDetail = false
                                    // Observation will auto-update, but refresh local for immediate feedback
                                    Task { await loadLocalAssignments() }
                                }
                            }
                        }
                }
            }
        }
    }
    
    private var aiPracticeCard: some View {
        Button {
            generateQuickPractice()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Practice Generator")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Get personalized problems for this class")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if generationService.isGenerating {
                    ProgressView()
                } else {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.purple)
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [.purple.opacity(0.1), .blue.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(generationService.isGenerating)
    }
    
    private var weakAreasSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.orange)
                Text("Focus Areas")
                    .font(.headline)
                
                Spacer()
            }
            
            ForEach(weakConcepts.prefix(3), id: \.id) { concept in
                ConceptPracticeRow(concept: concept) {
                    generatePracticeForConcept(concept)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(16)
    }
    
    private var allConceptsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Concepts")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(concepts, id: \.id) { concept in
                    ConceptCard(concept: concept) {
                        generatePracticeForConcept(concept)
                    }
                }
            }
        }
    }
    
    private func generateQuickPractice() {
        guard let userId = awsService.currentUserProfile?.userId else { return }
        
        Task {
            do {
                if !weakConcepts.isEmpty {
                    generatedProblems = try await generationService.generateForWeakAreas(
                        studentId: userId,
                        classroomId: classroom.id,
                        count: 10,
                        userId: userId
                    )
                } else if !concepts.isEmpty {
                    let conceptNames = concepts.prefix(3).map { $0.concept }
                    generatedProblems = try await generationService.generateForConcepts(
                        concepts: Array(conceptNames),
                        difficulty: .similar,
                        count: 10,
                        userId: userId
                    )
                }
                showingPracticeSession = true
            } catch {
                print("âš ï¸ Failed to generate practice: \(error)")
            }
        }
    }
    
    private func generatePracticeForConcept(_ concept: ConceptMastery) {
        guard let userId = awsService.currentUserProfile?.userId else { return }
        
        Task {
            do {
                generatedProblems = try await generationService.generateForConcept(
                    concept: concept.concept,
                    difficulty: .similar,
                    count: 10,
                    sourceWorksheetId: nil,
                    gradeLevel: classroom.gradeLevel,
                    userId: userId
                )
                showingPracticeSession = true
            } catch {
                print("âš ï¸ Failed to generate practice: \(error)")
            }
        }
    }

    // MARK: - Assigned Practice Section
    
    private var assignedPracticeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.badge.clock.fill")
                    .foregroundColor(.blue)
                Text("Assigned Practice")
                    .font(.headline)
                
                // Sync indicator
                if isSyncing {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Syncing...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if !pendingAssignments.isEmpty {
                    Text("\(pendingAssignments.count) pending")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .cornerRadius(8)
                }
            }
            
            if isLoadingAssignments {
                HStack {
                    ProgressView()
                    Text("Loading assignments...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if pendingAssignments.isEmpty && completedAssignments.isEmpty {
                Text("No practice assigned yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                // Pending assignments first
                ForEach(pendingAssignments, id: \.id) { assignment in
                    AssignedPracticeRow(
                        assignment: assignment,
                        onTap: {
                            selectedAssignment = assignment
                            showingAssignmentDetail = true
                        }
                    )
                }
                
                // Show completed (collapsed by default)
                if !completedAssignments.isEmpty {
                    DisclosureGroup {
                        ForEach(completedAssignments.prefix(3), id: \.id) { assignment in
                            AssignedPracticeRow(
                                assignment: assignment,
                                onTap: {
                                    selectedAssignment = assignment
                                    showingAssignmentDetail = true
                                }
                            )
                        }
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Completed (\(completedAssignments.count))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
    
    // MARK: - Load Assigned Practice (Hybrid Approach)
    
    /// Start observing assignments - shows local data immediately and syncs from cloud
    private func startObservingAssignments() {
        guard let userId = awsService.currentUserId else {
            print("⚠️ No userId available for assignment observation")
            return
        }
        
        print("🔍 Starting assignment observation")
        print("   Current userId: \(userId)")
        print("   Current classroomId: \(classroom.id)")
        
        // Cancel any existing observation
        observationTask?.cancel()
        
        isLoadingAssignments = true
        
        observationTask = Task {
            do {
                // First, let's query ALL assignments to see what exists (debug)
                let allAssignments = try await Amplify.DataStore.query(PracticeAssignment.self)
                print("📊 DEBUG: Total assignments in DataStore: \(allAssignments.count)")
                for assignment in allAssignments {
                    print("   📄 Assignment: \(assignment.title)")
                    print("      id: \(assignment.id)")
                    print("      studentId: \(assignment.studentId)")
                    print("      classroomId: \(assignment.classroomId ?? "nil")")
                    print("      match studentId? \(assignment.studentId == userId)")
                    print("      match classroomId? \(assignment.classroomId == classroom.id || assignment.classroomId == nil)")
                }
                
                // Use observeQuery for real-time updates - query ALL then filter client-side
                let stream = Amplify.DataStore.observeQuery(
                    for: PracticeAssignment.self
                )
                
                for try await snapshot in stream {
                    // Check if task was cancelled
                    if Task.isCancelled {
                        print("📛 Observation task cancelled")
                        break
                    }
                    
                    await MainActor.run {
                        print("📦 Received snapshot: \(snapshot.items.count) total assignments, isSynced: \(snapshot.isSynced)")
                        
                        // Debug: log all assignments received
                        for assignment in snapshot.items {
                            print("   - Assignment: \(assignment.title)")
                            print("     studentId: \(assignment.studentId) (looking for: \(userId))")
                            print("     classroomId: \(assignment.classroomId ?? "nil") (looking for: \(classroom.id) or nil)")
                        }
                        
                        // Filter by studentId AND (classroomId OR nil)
                        let filtered = snapshot.items
                            .filter { $0.studentId == userId && ($0.classroomId == classroom.id || $0.classroomId == nil) }
                            .sorted { a1, a2 in
                                // Sort: pending first, then by assigned date (newest first)
                                if a1.statusEnum != .completed && a2.statusEnum == .completed {
                                    return true
                                } else if a1.statusEnum == .completed && a2.statusEnum != .completed {
                                    return false
                                }
                                return a1.assignedDate.foundationDate > a2.assignedDate.foundationDate
                            }
                        
                        print("📋 Filtered to \(filtered.count) assignments for this student/classroom")
                        
                        assignedPractice = filtered
                        isLoadingAssignments = false
                        isSyncing = snapshot.isSynced ? false : true
                        
                        if snapshot.isSynced {
                            print("✅ Practice assignments synced from cloud: \(filtered.count) items")
                        } else {
                            print("📦 Showing local practice assignments: \(filtered.count) items (syncing...)")
                        }
                    }
                }
            } catch {
                if Task.isCancelled || error is CancellationError {
                    print("📛 Observation cancelled (expected during navigation)")
                } else {
                    print("⚠️ Failed to observe assignments: \(error)")
                }
                await MainActor.run {
                    isLoadingAssignments = false
                }
            }
        }
    }
    
    /// Force refresh from cloud (for pull-to-refresh)
    private func refreshAssignmentsFromCloud() async {
        guard let userId = awsService.currentUserId else { return }
        
        isSyncing = true
        
        print("🔄 Refreshing assignments from cloud for userId: \(userId)")
        
        do {
            // Query fresh data - don't use Task.sleep which can be cancelled
            let allAssignments = try await Amplify.DataStore.query(PracticeAssignment.self)
            
            print("📦 Query returned \(allAssignments.count) total assignments")
            
            // Debug: log all assignments
            for assignment in allAssignments {
                print("   - Assignment: \(assignment.title)")
                print("     studentId: \(assignment.studentId)")
                print("     classroomId: \(assignment.classroomId ?? "nil")")
                print("     Looking for studentId: \(userId), classroomId: \(classroom.id)")
            }
            
            let filtered = allAssignments
                .filter { $0.studentId == userId && ($0.classroomId == classroom.id || $0.classroomId == nil) }
                .sorted { a1, a2 in
                    if a1.statusEnum != .completed && a2.statusEnum == .completed {
                        return true
                    } else if a1.statusEnum == .completed && a2.statusEnum != .completed {
                        return false
                    }
                    return a1.assignedDate.foundationDate > a2.assignedDate.foundationDate
                }
            
            assignedPractice = filtered
            isSyncing = false
            print("🔄 Refreshed assignments: \(filtered.count) items for this classroom")
        } catch {
            if error is CancellationError {
                print("📛 Refresh cancelled (expected during navigation)")
            } else {
                print("⚠️ Failed to refresh assignments: \(error)")
            }
            isSyncing = false
        }
    }
    
    /// Load local data only (for quick display)
    private func loadLocalAssignments() async {
        guard let userId = awsService.currentUserId else { return }
        
        do {
            let allAssignments = try await Amplify.DataStore.query(PracticeAssignment.self)
            
            assignedPractice = allAssignments
                .filter { $0.studentId == userId && ($0.classroomId == classroom.id || $0.classroomId == nil) }
                .sorted { a1, a2 in
                    if a1.statusEnum != .completed && a2.statusEnum == .completed {
                        return true
                    } else if a1.statusEnum == .completed && a2.statusEnum != .completed {
                        return false
                    }
                    return a1.assignedDate.foundationDate > a2.assignedDate.foundationDate
                }
            
            print("📋 Loaded \(assignedPractice.count) local assignments")
        } catch {
            print("⚠️ Failed to load local assignments: \(error)")
        }
    }
}

// MARK: - Assigned Practice Row

private struct AssignedPracticeRow: View {
    let assignment: PracticeAssignment
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Status Icon
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: statusIcon)
                        .font(.title3)
                        .foregroundColor(statusColor)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(assignment.title)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Label("\(assignment.problemCount) problems", systemImage: "number")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(assignment.sourceTypeDisplayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Due date or completion status
                    if assignment.statusEnum == .completed {
                        if let score = assignment.score {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Completed - \(Int(score))%")
                                    .foregroundColor(.green)
                            }
                            .font(.caption)
                        }
                    } else if let dueDate = assignment.dueDate {
                        let isOverdue = dueDate.foundationDate < Date()
                        HStack(spacing: 4) {
                            Image(systemName: isOverdue ? "exclamationmark.triangle.fill" : "clock.fill")
                                .foregroundColor(isOverdue ? .red : .orange)
                            Text(isOverdue ? "Overdue" : "Due \(dueDate.foundationDate, style: .relative)")
                                .foregroundColor(isOverdue ? .red : .orange)
                        }
                        .font(.caption)
                    }
                }
                
                Spacer()
                
                VStack {
                    Image(systemName: assignment.statusEnum == .completed ? "eye.fill" : "play.fill")
                        .foregroundColor(assignment.statusEnum == .completed ? .secondary : .blue)
                    
                    Text(assignment.statusEnum == .completed ? "View" : "Start")
                        .font(.caption2)
                        .foregroundColor(assignment.statusEnum == .completed ? .secondary : .blue)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusColor: Color {
        switch assignment.statusEnum {
        case .pending: return .blue
        case .inProgress: return .orange
        case .completed: return .green
        }
    }
    
    private var statusIcon: String {
        switch assignment.statusEnum {
        case .pending: return "circle"
        case .inProgress: return "circle.lefthalf.filled"
        case .completed: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Concept Practice Row

private struct ConceptPracticeRow: View {
    let concept: ConceptMastery
    let onPractice: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Mastery Circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: concept.masteryPercentage / 100)
                    .stroke(masteryColor, lineWidth: 3)
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(concept.masteryPercentage))")
                    .font(.caption2.bold())
                    .foregroundColor(masteryColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(concept.concept)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                
                Text("\(concept.totalAttempts) attempts")
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
}

// MARK: - Concept Card

private struct ConceptCard: View {
    let concept: ConceptMastery
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(concept.concept)
                    .font(.caption.bold())
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)
                            .cornerRadius(2)
                        
                        Rectangle()
                            .fill(masteryColor)
                            .frame(width: geometry.size.width * (concept.masteryPercentage / 100), height: 4)
                            .cornerRadius(2)
                    }
                }
                .frame(height: 4)
                
                HStack {
                    Text("\(Int(concept.masteryPercentage))%")
                        .font(.caption2)
                        .foregroundColor(masteryColor)
                    
                    Spacer()
                    
                    Image(systemName: "play.circle.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.03), radius: 4, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var masteryColor: Color {
        if concept.masteryPercentage >= 80 { return .green }
        if concept.masteryPercentage >= 60 { return .yellow }
        return .orange
    }
}

// MARK: - Worksheets Tab View

private struct WorksheetsTabView: View {
    let worksheets: [Worksheet]
    let classroom: Classroom
    let classColor: Color
    
    @State private var showingUpload = false
    @StateObject private var vm = ExtractViewModel()
    @State private var selectedWorksheet: Worksheet?
    @State private var showingWorksheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Upload Card
                uploadCard
                
                // Worksheets List
                if !worksheets.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Worksheets")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("\(worksheets.count)")
                                .font(.caption.bold())
                                .foregroundColor(classColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(classColor.opacity(0.15))
                                .cornerRadius(8)
                        }
                        
                        ForEach(worksheets, id: \.id) { worksheet in
                            WorksheetRowCard(worksheet: worksheet) {
                                selectedWorksheet = worksheet
                                showingWorksheet = true
                            }
                        }
                    }
                }
                
                // Empty State
                if worksheets.isEmpty {
                    EmptyTabView(
                        icon: "doc.fill",
                        title: "No Worksheets Yet",
                        message: "Upload worksheets to practice and get AI feedback on your solutions.",
                        color: classColor
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingUpload) {
            NewWorksheetUploadView(
                onWorksheetUploaded: { _ in
                    showingUpload = false
                },
                onCancel: {
                    showingUpload = false
                }
            )
        }
        .sheet(isPresented: $showingWorksheet) {
            if let worksheet = selectedWorksheet,
               let extracted = try? vm.getQuestionsFromWorksheet(worksheet) {
                NavigationStack {
                    JSONPreviewView(result: extracted, savedWorksheetId: worksheet.id)
                        .navigationTitle(worksheet.title)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showingWorksheet = false
                                }
                            }
                        }
                }
            }
        }
    }
    
    private var uploadCard: some View {
        Button {
            showingUpload = true
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(classColor.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "doc.badge.plus")
                        .font(.title3)
                        .foregroundColor(classColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Upload Worksheet")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Scan or upload to practice")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(classColor)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.03), radius: 4, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Worksheet Row Card

private struct WorksheetRowCard: View {
    let worksheet: Worksheet
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: iconName)
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(worksheet.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 12) {
                        if let questionCount = worksheet.questionCount {
                            Label("\(questionCount) questions", systemImage: "number")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(worksheet.uploadedAt.foundationDate, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.03), radius: 4, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var iconName: String {
        switch worksheet.fileType?.lowercased() {
        case "pdf": return "doc.richtext.fill"
        case "docx", "doc": return "doc.text.fill"
        case "jpg", "jpeg", "png": return "photo.fill"
        default: return "doc.fill"
        }
    }
}

// MARK: - Empty Tab View

private struct EmptyTabView: View {
    let icon: String
    let title: String
    let message: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color.opacity(0.5))
            }
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Worksheet Detail Placeholder
// (Keep for compatibility - replace with your actual worksheet detail view)

struct WorksheetDetailPlaceholder: View {
    let worksheet: Worksheet
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Worksheet Detail")
                    .font(.title2.bold())
                
                Text(worksheet.title)
                    .font(.headline)
                
                Text("Replace this view with your existing WorksheetDetailView")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                if let questionCount = worksheet.questionCount {
                    Text("\(questionCount) questions extracted")
                }
                
                if worksheet.extractionResult != nil {
                    Text("Extraction completed")
                        .foregroundColor(.green)
                }
            }
            .padding()
        }
        .navigationTitle("Worksheet")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Stat Card (For compatibility with other views)

struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
}
