//
//  ParentChildAnalyticsView.swift
//  PeaTutorApp
//
//  Sprint 7.3: Parent Analytics & Progress Tracking
//  Parent-friendly analytics view for a single child
//

import SwiftUI
import Amplify

struct ParentChildAnalyticsView: View {
    let child: UserProfile
    let classroom: Classroom?
    
    @StateObject private var queryService = AnalyticsQueryService.shared
    @StateObject private var analyticsService = AnalyticsService.shared
    
    // Data state
    @State private var conceptMastery: [ConceptMastery] = []
    @State private var errorPatterns: [ErrorPattern] = []
    @State private var cognitiveProfile: CognitiveProfile?
    @State private var studentSummary: StudentAnalyticsSummary?
    @State private var studentProgress: StudentProgress?
    @State private var classAverages: ClassAverages?
    
    // UI state
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedTab: ParentAnalyticsTab = .curriculum
    
    @State private var showingPracticeGeneration = false
    @State private var selectedConceptsForPractice: [String] = []
    
    enum ParentAnalyticsTab: String, CaseIterable {
        //case overview = "Overview"
        case curriculum = "Curriculum"
        case strengths = "Strengths"
        case needsHelp = "Needs Help"
        case howToHelp = "How to Help"
        
        
        var icon: String {
            switch self {
            //case .overview: return "chart.bar.fill"
            case .curriculum: return "book.closed.fill"
            case .strengths: return "star.fill"
            case .needsHelp: return "exclamationmark.triangle.fill"
            case .howToHelp: return "lightbulb.fill"
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Child Header with Progress Ring
                //childHeaderCard
                
                // Quick Insights Cards
                //quickInsightsSection
                
                // Tab Selector
                tabSelector
                
                // Content based on selected tab
                Group {
                    if isLoading {
                        loadingView
                    } else {
                        tabContent
                    }
                }
            }
            .padding()
        }
        .navigationTitle("\(child.displayName)'s Progress")
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
        .sheet(isPresented: $showingPracticeGeneration) {
            PracticeGenerationView(
                child: child,
                concepts: selectedConceptsForPractice,
                suggestedDifficulty: .easier
            )
        }
    }
    
    // MARK: - Child Header Card
    
    private var childHeaderCard: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                // Progress Ring with Avatar
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 90, height: 90)
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0, to: CGFloat((studentSummary?.overallProgress ?? 0) / 100))
                        .stroke(
                            progressGradient,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.8), value: studentSummary?.overallProgress)
                    
                    // Avatar
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .overlay(
                            Text(child.initials)
                                .font(.title.bold())
                                .foregroundColor(.white)
                        )
                }
                
                // Child Info & Progress
                VStack(alignment: .leading, spacing: 8) {
                    Text(child.displayName)
                        .font(.title2.bold())
                    
                    if let gradeLevel = child.gradeLevel {
                        Label(gradeLevel, systemImage: "graduationcap")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let classroom = classroom {
                        Label(classroom.className, systemImage: "book.closed")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Overall Progress Score
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(studentSummary?.overallProgress ?? 0))%")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(overallProgressColor)
                    
                    Text("Overall")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    progressStatusBadge
                }
            }
            
            // Homework Completion Stats
            if let progress = studentProgress {
                homeworkCompletionBar(progress: progress)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    private var progressGradient: LinearGradient {
        let progress = studentSummary?.overallProgress ?? 0
        let colors: [Color] = progress >= 70 ? [.green, .green.opacity(0.7)] :
                              progress >= 50 ? [.orange, .yellow] :
                              [.red, .orange]
        return LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
    }
    
    private var overallProgressColor: Color {
        let progress = studentSummary?.overallProgress ?? 0
        return progress >= 70 ? .green : progress >= 50 ? .orange : .red
    }
    
    private var progressStatusBadge: some View {
        let progress = studentSummary?.overallProgress ?? 0
        let (text, color, icon): (String, Color, String) = {
            if progress >= 80 { return ("Excellent!", .green, "star.fill") }
            if progress >= 70 { return ("On Track", .green, "checkmark.circle.fill") }
            if progress >= 50 { return ("Making Progress", .orange, "arrow.up.right") }
            return ("Needs Support", .red, "heart.fill")
        }()
        
        return HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2.bold())
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func homeworkCompletionBar(progress: StudentProgress) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Homework Completion")
                    .font(.subheadline.bold())
                Spacer()
                Text("\(progress.totalHomeworkCompleted)/\(progress.totalHomeworkAssigned)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                    
                    // Completed (green)
                    let completedWidth = progress.totalHomeworkAssigned > 0 ?
                        CGFloat(progress.totalHomeworkCompleted - progress.totalHomeworkLate) / CGFloat(progress.totalHomeworkAssigned) * geometry.size.width : 0
                    
                    // Late (orange)
                    let lateWidth = progress.totalHomeworkAssigned > 0 ?
                        CGFloat(progress.totalHomeworkLate) / CGFloat(progress.totalHomeworkAssigned) * geometry.size.width : 0
                    
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: completedWidth)
                        
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: lateWidth)
                    }
                    .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            // Legend
            HStack(spacing: 16) {
                LegendItem2(color: .green, text: "On Time")
                LegendItem2(color: .orange, text: "Late")
                LegendItem2(color: .gray.opacity(0.3), text: "Missing")
            }
            .font(.caption2)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Quick Insights Section
    
    private var quickInsightsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Mastered Concepts
                ParentInsightCard(
                    icon: "checkmark.seal.fill",
                    title: "Mastered",
                    value: "\(studentSummary?.masteredConcepts.count ?? 0)",
                    subtitle: "concepts",
                    color: .green,
                    trend: nil
                )
                
                // Accuracy
                ParentInsightCard(
                    icon: "target",
                    title: "Accuracy",
                    value: "\(Int(studentSummary?.overallAccuracy ?? 0))%",
                    subtitle: "correct answers",
                    color: .blue,
                    trend: nil
                )
                
                // Current Streak
                ParentInsightCard(
                    icon: "flame.fill",
                    title: "Streak",
                    value: "\(studentSummary?.currentStreak ?? 0)",
                    subtitle: "days",
                    color: .orange,
                    trend: nil
                )
                
                // Areas to Focus
                ParentInsightCard(
                    icon: "book.fill",
                    title: "To Focus",
                    value: "\(studentSummary?.needsWorkConcepts.count ?? 0)",
                    subtitle: "topics",
                    color: .purple,
                    trend: nil
                )
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ParentAnalyticsTab.allCases, id: \.self) { tab in
                    ParentTabButton(
                        title: tab.rawValue,
                        icon: tab.icon,
                        isSelected: selectedTab == tab
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedTab = tab
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Tab Content
    
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        //case .overview:
        //    overviewTab
        
        case .curriculum:
             curriculumTab
        
        case .strengths:
            strengthsTab
            
        case .needsHelp:
            needsHelpTab
            
        case .howToHelp:
            howToHelpTab
        }
    }
    
    // MARK: - Overview Tab
    
    private var overviewTab: some View {
        VStack(spacing: 20) {
            // Skills Radar Chart
            if let profile = cognitiveProfile {
                ParentSkillsOverviewCard(profile: profile)
            }
            
            // Recent Progress
            if !conceptMastery.isEmpty {
                ParentConceptProgressCard(concepts: conceptMastery)
            } else {
                emptyStateCard(
                    icon: "chart.bar",
                    title: "No Progress Data Yet",
                    message: "Progress will appear here after your child completes homework"
                )
            }
            
            // Class Comparison (if available)
            if let averages = classAverages {
                classComparisonCard(averages: averages)
            }
        }
    }
    
    // MARK: - Curriculum Tab
    private var curriculumTab: some View {
            VStack(spacing: 20) {
                // Strand & SubStrand Progress View (reusable component)
                CurriculumStrandProgressView(
                    studentId: child.userId,
                    classroomId: classroom?.id,
                    gradeLevel: classroom?.gradeLevel ?? child.gradeLevel ?? "Primary 1",
                    studentName: child.displayName,
                    showHeader: true,
                    accentColor: .purple
                )
                
                // Parent Tips
                parentCurriculumTips
            }
        }
        
        private var parentCurriculumTips: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text("How to Help")
                        .font(.headline)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    TipRow(emoji: "📖", text: "Review topics marked 'Learning' together")
                    TipRow(emoji: "⏰", text: "Short daily practice is better than long sessions")
                    TipRow(emoji: "🎯", text: "Focus on prerequisite gaps first")
                    TipRow(emoji: "🌟", text: "Celebrate mastered topics!")
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        }
    
    // MARK: - Strengths Tab
    
    private var strengthsTab: some View {
        VStack(spacing: 16) {
            if let summary = studentSummary, !summary.masteredConcepts.isEmpty {
                // Celebration header
                celebrationHeader
                
                // Mastered concepts list
                ForEach(summary.masteredConcepts, id: \.self) { concept in
                    if let mastery = conceptMastery.first(where: { $0.concept == concept }) {
                        ParentMasteredConceptRow(concept: mastery)
                    }
                }
                
                // Top Strengths
                if !summary.topStrengths.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Top Strengths")
                            .font(.headline)
                        
                        ForEach(summary.topStrengths, id: \.self) { strength in
                            HStack(spacing: 12) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(strength)
                                    .font(.subheadline)
                                Spacer()
                            }
                            .padding()
                            .background(Color.yellow.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
            } else {
                emptyStateCard(
                    icon: "star",
                    title: "Building Strengths",
                    message: "As your child masters concepts, they'll appear here. Keep encouraging them!"
                )
            }
        }
    }
    
    private var celebrationHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: "party.popper.fill")
                .font(.system(size: 40))
                .foregroundStyle(.yellow.gradient)
            
            Text("Great Job!")
                .font(.title2.bold())
            
            Text("\(child.displayName) has mastered \(studentSummary?.masteredConcepts.count ?? 0) concepts!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            LinearGradient(
                colors: [.yellow.opacity(0.1), .orange.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
    
    // MARK: - Needs Help Tab

    private var needsHelpTab: some View {
        VStack(spacing: 16) {
            if let summary = studentSummary, !summary.needsWorkConcepts.isEmpty {
                // Encouragement header
                encouragementHeader
                
                // NEW: Quick Practice All Button
                practiceAllWeakAreasButton(concepts: summary.needsWorkConcepts)
                
                // Concepts needing work
                ForEach(summary.needsWorkConcepts, id: \.self) { concept in
                    if let mastery = conceptMastery.first(where: { $0.concept == concept }) {
                        ParentNeedsWorkConceptRowWithPractice(
                            concept: mastery,
                            onPractice: {
                                selectedConceptsForPractice = [mastery.concept]
                                showingPracticeGeneration = true
                            }
                        )
                    }
                }
                
                // Common Errors (simplified for parents)
                if !errorPatterns.isEmpty {
                    commonErrorsSection
                }
            } else if let summary = studentSummary, summary.needsWorkConcepts.isEmpty && !summary.masteredConcepts.isEmpty {
                // All caught up!
                allCaughtUpCard
            } else {
                emptyStateCard(
                    icon: "checkmark.circle",
                    title: "Keep Up the Good Work",
                    message: "Complete more homework to see areas that need extra practice"
                )
            }
        }
    }  // <-- needsHelpTab ENDS HERE
    
    // MARK: - Practice All Weak Areas Button

    private func practiceAllWeakAreasButton(concepts: [String]) -> some View {
        Button(action: {
            selectedConceptsForPractice = concepts
            showingPracticeGeneration = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Practice All Weak Areas")
                        .font(.headline)
                    Text("Generate \(concepts.count > 1 ? "problems for all \(concepts.count) concepts" : "focused practice")")
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
            .cornerRadius(16)
        }
    }
    
    private var encouragementHeader: some View {
        HStack(spacing: 16) {
            Image(systemName: "heart.fill")
                .font(.title)
                .foregroundColor(.pink)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Areas to Practice Together")
                    .font(.headline)
                Text("These topics need a little extra attention. You can help!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.pink.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var commonErrorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Common Mistakes to Watch For")
                .font(.headline)
            
            ForEach(errorPatterns.filter { $0.isActive }.prefix(3), id: \.id) { error in
                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .fill(severityColor(error.severityLevel))
                        .frame(width: 8, height: 8)
                        .padding(.top, 6)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(error.errorType)
                            .font(.subheadline.bold())
                        
                        Text(error.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            }
        }
    }
    
    private var allCaughtUpCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)
            
            Text("All Caught Up!")
                .font(.title2.bold())
            
            Text("Your child is doing great and doesn't have any major areas needing extra help right now.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(Color.green.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - How to Help Tab
    
    private var howToHelpTab: some View {
        VStack(spacing: 16) {
            // NEW: Smart Practice Recommendation
                    NavigationLink(destination: WeakAreaPracticeView(
                        child: child,
                        classroomId: classroom?.id
                    )) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.purple.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "brain.head.profile")
                                    .font(.title2)
                                    .foregroundColor(.purple)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("AI-Recommended Practice")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Smart problems based on weak areas")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
                    }
                    .buttonStyle(PlainButtonStyle())
            
            // Parent Action Cards
            ParentActionableInsightsSection(
                studentSummary: studentSummary,
                errorPatterns: errorPatterns,
                childName: child.displayName
            )
        }
    }
    
    // MARK: - Class Comparison Card
    
    private func classComparisonCard(averages: ClassAverages) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundColor(.blue)
                Text("Compared to Class")
                    .font(.headline)
            }
            
            let childProgress = studentSummary?.overallProgress ?? 0
            let difference = childProgress - averages.averageProgress
            
            HStack(spacing: 20) {
                // Child's score
                VStack(spacing: 4) {
                    Text("\(Int(childProgress))%")
                        .font(.title2.bold())
                        .foregroundColor(.blue)
                    Text(child.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Comparison indicator
                VStack(spacing: 4) {
                    Image(systemName: difference >= 0 ? "arrow.up" : "arrow.down")
                        .font(.title3)
                        .foregroundColor(difference >= 0 ? .green : .orange)
                    Text("\(abs(Int(difference)))%")
                        .font(.subheadline.bold())
                        .foregroundColor(difference >= 0 ? .green : .orange)
                }
                
                // Class average
                VStack(spacing: 4) {
                    Text("\(Int(averages.averageProgress))%")
                        .font(.title2.bold())
                        .foregroundColor(.gray)
                    Text("Class Avg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Interpretation
            Text(difference >= 10 ? "Excellent! \(child.displayName) is performing above the class average." :
                 difference >= 0 ? "\(child.displayName) is keeping pace with the class." :
                 difference >= -10 ? "A little extra practice could help catch up to the class." :
                 "Consider some focused practice sessions to build confidence.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
    
    // MARK: - Helper Views
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading \(child.displayName)'s progress...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
    }
    
    private func emptyStateCard(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private func severityColor(_ severity: ErrorSeverity) -> Color {
        switch severity {
        case .high: return .red
        case .medium: return .orange
        case .low: return .yellow
        }
    }
    
    // MARK: - Load Analytics
    
    private func loadAnalytics() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch all analytics data in parallel
            async let concepts = queryService.fetchConceptMastery(
                studentId: child.userId,
                classroomId: classroom?.id
            )
            
            async let errors = queryService.fetchErrorPatterns(
                studentId: child.userId,
                classroomId: classroom?.id
            )
            
            async let profile = queryService.calculateCognitiveProfile(
                studentId: child.userId,
                classroomId: classroom?.id
            )
            
            async let summary = queryService.fetchStudentSummary(
                studentId: child.userId,
                classroomId: classroom?.id
            )
            
            let (fetchedConcepts, fetchedErrors, fetchedProfile, fetchedSummary) = try await (
                concepts,
                errors,
                profile,
                summary
            )
            
            // Fetch student progress
            let allProgress = try await Amplify.DataStore.query(StudentProgress.self)
            let progress = allProgress.first { $0.studentId == child.userId &&
                (classroom == nil || $0.classroom?.id == classroom?.id) }
            
            // Calculate class averages if in a classroom
            var averages: ClassAverages? = nil
            if let classroom = classroom {
                averages = try await calculateClassAverages(classroomId: classroom.id)
            }
            
            await MainActor.run {
                self.conceptMastery = fetchedConcepts
                self.errorPatterns = fetchedErrors
                self.cognitiveProfile = fetchedProfile
                self.studentSummary = fetchedSummary
                self.studentProgress = progress
                self.classAverages = averages
            }
            
            print("✅ Parent analytics loaded: \(fetchedConcepts.count) concepts, \(fetchedErrors.count) errors")
            
        } catch {
            errorMessage = "Failed to load progress: \(error.localizedDescription)"
            print("❌ Parent analytics error: \(error)")
        }
    }
    
    private func calculateClassAverages(classroomId: String) async throws -> ClassAverages {
        // Get all concept mastery for this classroom
        let allMastery = try await Amplify.DataStore.query(ConceptMastery.self)
        let classMastery = allMastery.filter { $0.classroomId == classroomId }
        
        // Calculate average progress
        let studentIds = Set(classMastery.map { $0.studentId })
        var studentProgressValues: [Double] = []
        
        for studentId in studentIds {
            let studentConcepts = classMastery.filter { $0.studentId == studentId }
            if !studentConcepts.isEmpty {
                let avgMastery = studentConcepts.reduce(0.0) { $0 + $1.masteryPercentage } / Double(studentConcepts.count)
                studentProgressValues.append(avgMastery)
            }
        }
        
        let averageProgress = studentProgressValues.isEmpty ? 0 :
            studentProgressValues.reduce(0, +) / Double(studentProgressValues.count)
        
        return ClassAverages(
            averageProgress: averageProgress,
            totalStudents: studentIds.count
        )
    }
}

// MARK: - Supporting Types

struct ClassAverages {
    let averageProgress: Double
    let totalStudents: Int
}

// MARK: - Legend Item

struct LegendItem2: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Parent Insight Card

struct ParentInsightCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let trend: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
                if let trend = trend {
                    Text(trend)
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            
            Text(value)
                .font(.title2.bold())
            
            Text(title)
                .font(.caption.bold())
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 100)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Parent Tab Button

struct ParentTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline)
                
                Text(title)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.purple : Color(.secondarySystemBackground))
            )
        }
    }
}

// MARK: - Parent Skills Overview Card

struct ParentSkillsOverviewCard: View {
    let profile: CognitiveProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Skills Overview")
                .font(.headline)
            
            // Simplified skill bars instead of radar chart
            VStack(spacing: 12) {
                SkillBar(name: "Computation", value: profile.computation, color: .blue)
                SkillBar(name: "Word Problems", value: profile.wordProblems, color: .purple)
                SkillBar(name: "Problem Solving", value: profile.problemSolving, color: .orange)
                SkillBar(name: "Reasoning", value: profile.reasoning, color: .green)
                SkillBar(name: "Accuracy", value: profile.accuracy, color: .red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
}

struct SkillBar: View {
    let name: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .font(.caption)
                Spacer()
                Text("\(Int(value))%")
                    .font(.caption.bold())
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(value / 100))
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Parent Concept Progress Card

struct ParentConceptProgressCard: View {
    let concepts: [ConceptMastery]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Concept Progress")
                    .font(.headline)
                Spacer()
                Text("\(concepts.count) topics")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ForEach(concepts.prefix(5), id: \.id) { concept in
                HStack {
                    Text(concept.concept)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    // Mini progress bar
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 60, height: 6)
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(masteryColor(concept.masteryPercentage))
                            .frame(width: 60 * CGFloat(concept.masteryPercentage / 100), height: 6)
                    }
                    
                    Text("\(Int(concept.masteryPercentage))%")
                        .font(.caption.bold())
                        .foregroundColor(masteryColor(concept.masteryPercentage))
                        .frame(width: 40, alignment: .trailing)
                }
            }
            
            if concepts.count > 5 {
                Text("+ \(concepts.count - 5) more topics")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
    
    private func masteryColor(_ percentage: Double) -> Color {
        if percentage >= 80 { return .green }
        if percentage >= 60 { return .orange }
        return .red
    }
}

// MARK: - Parent Mastered Concept Row

struct ParentMasteredConceptRow: View {
    let concept: ConceptMastery
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(concept.concept)
                    .font(.subheadline.bold())
                
                Text("\(Int(concept.masteryPercentage))% mastery • \(concept.totalAttempts) questions completed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Parent Needs Work Concept Row

struct ParentNeedsWorkConceptRow: View {
    let concept: ConceptMastery
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.orange, lineWidth: 3)
                    .frame(width: 40, height: 40)
                
                Text("\(Int(concept.masteryPercentage))%")
                    .font(.caption.bold())
                    .foregroundColor(.orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(concept.concept)
                    .font(.subheadline.bold())
                
                Text(suggestionForConcept(concept))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func suggestionForConcept(_ concept: ConceptMastery) -> String {
        if concept.masteryPercentage < 40 {
            return "Needs regular practice • Start with basics"
        } else if concept.masteryPercentage < 60 {
            return "Making progress • A bit more practice will help"
        } else {
            return "Almost there! • Just a few more sessions"
        }
    }
}

// MARK: - Parent Actionable Insights Section

struct ParentActionableInsightsSection: View {
    let studentSummary: StudentAnalyticsSummary?
    let errorPatterns: [ErrorPattern]
    let childName: String
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("How You Can Help")
                        .font(.headline)
                    Text("Practical tips for supporting \(childName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(12)
            
            // Action cards based on analysis
            ForEach(generateParentActions(), id: \.id) { action in
                ParentActionCard(action: action)
            }
        }
    }
    
    private func generateParentActions() -> [ParentAction] {
        var actions: [ParentAction] = []
        
        guard let summary = studentSummary else {
            return [ParentAction(
                id: "encourage",
                icon: "heart.fill",
                iconColor: .pink,
                title: "Keep Encouraging",
                description: "Regular homework completion is the best way to track progress.",
                tips: ["Set a regular homework time", "Create a quiet study space", "Celebrate small wins"]
            )]
        }
        
        // Based on needs work concepts
        if !summary.needsWorkConcepts.isEmpty {
            let concept = summary.needsWorkConcepts.first!
            actions.append(ParentAction(
                id: "focus-\(concept)",
                icon: "target",
                iconColor: .orange,
                title: "Focus on \(concept)",
                description: "This is the area that needs the most attention right now.",
                tips: [
                    "Spend 10-15 minutes daily on \(concept.lowercased()) practice",
                    "Use real-world examples (shopping, cooking, etc.)",
                    "Ask the teacher for extra worksheets"
                ]
            ))
        }
        
        // Based on error patterns
        let highErrors = errorPatterns.filter { $0.severityLevel == .high && $0.isActive }
        if let error = highErrors.first {
            actions.append(ParentAction(
                id: "error-\(error.id)",
                icon: "exclamationmark.triangle.fill",
                iconColor: .red,
                title: "Watch for: \(error.errorType)",
                description: "This is a common mistake. Being aware of it can help.",
                tips: [
                    "Ask your child to explain their steps out loud",
                    "Double-check work together before submitting",
                    error.remediation ?? "Practice similar problems slowly"
                ]
            ))
        }
        
        // Based on strengths
        if !summary.topStrengths.isEmpty {
            let strength = summary.topStrengths.first!
            actions.append(ParentAction(
                id: "strength-\(strength)",
                icon: "star.fill",
                iconColor: .yellow,
                title: "Celebrate \(strength)",
                description: "\(childName) is doing great here! Use this strength to build confidence.",
                tips: [
                    "Praise their \(strength.lowercased()) skills",
                    "Let them help younger siblings with this topic",
                    "Challenge them with harder problems for fun"
                ]
            ))
        }
        
        // General encouragement
        if summary.overallProgress >= 70 {
            actions.append(ParentAction(
                id: "great-progress",
                icon: "hands.clap.fill",
                iconColor: .green,
                title: "Great Progress!",
                description: "\(childName) is on track. Keep up the positive encouragement!",
                tips: [
                    "Continue the current study routine",
                    "Consider enrichment activities",
                    "Share progress with \(childName) to boost confidence"
                ]
            ))
        } else {
            actions.append(ParentAction(
                id: "building-skills",
                icon: "figure.walk",
                iconColor: .blue,
                title: "Building Skills",
                description: "Every student learns at their own pace. Consistent practice is key.",
                tips: [
                    "Short, daily practice is better than long sessions",
                    "Stay positive - frustration slows learning",
                    "Consider asking about tutoring options"
                ]
            ))
        }
        
        return actions
    }
}

// MARK: - Parent Action

struct ParentAction: Identifiable {
    let id: String
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let tips: [String]
}

// MARK: - Parent Action Card

struct ParentActionCard: View {
    let action: ParentAction
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack(spacing: 12) {
                    Image(systemName: action.icon)
                        .font(.title2)
                        .foregroundColor(action.iconColor)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(action.title)
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)
                        
                        Text(action.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(isExpanded ? nil : 2)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    Text("Tips:")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    
                    ForEach(Array(action.tips.enumerated()), id: \.offset) { index, tip in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .font(.subheadline)
                                .foregroundColor(action.iconColor)
                            
                            Text(tip)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Parent Needs Work Concept Row With Practice

struct ParentNeedsWorkConceptRowWithPractice: View {
    let concept: ConceptMastery
    let onPractice: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(Color.orange, lineWidth: 3)
                        .frame(width: 40, height: 40)
                    
                    Text("\(Int(concept.masteryPercentage))%")
                        .font(.caption.bold())
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(concept.concept)
                        .font(.subheadline.bold())
                    
                    Text(suggestionForConcept(concept))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            
            // Practice Button
            Button(action: onPractice) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Practice This")
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                .foregroundColor(.purple)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.purple.opacity(0.1))
            }
        }
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func suggestionForConcept(_ concept: ConceptMastery) -> String {
        if concept.masteryPercentage < 40 {
            return "Needs regular practice • Start with basics"
        } else if concept.masteryPercentage < 60 {
            return "Making progress • A bit more practice will help"
        } else {
            return "Almost there! • Just a few more sessions"
        }
    }
}
