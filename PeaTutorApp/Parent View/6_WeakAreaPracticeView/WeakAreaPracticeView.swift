//
//  WeakAreaPracticeView.swift
//  PeaTutorApp
//
//  Sprint 7.4: AI-Powered Practice Generation
//  AI-recommended practice based on student weaknesses
//

import SwiftUI
import Amplify

struct WeakAreaPracticeView: View {
    let child: UserProfile
    let classroomId: String?
    
    @StateObject private var generationService = PracticeGenerationService.shared
    @StateObject private var queryService = AnalyticsQueryService.shared
    @StateObject private var awsService = AWSService.shared
    
    @State private var weakConcepts: [ConceptMastery] = []
    @State private var errorPatterns: [ErrorPattern] = []
    @State private var isLoading = false
    @State private var generatedProblems: [PracticeProblem] = []
    @State private var showingPracticeSession = false
    @State private var showingAssignPractice = false
    @State private var errorMessage: String?
    
    @Environment(\.dismiss) private var dismiss
    
    // Check if current user is parent or teacher (can assign)
    private var canAssign: Bool {
        let role = awsService.currentUserProfile?.userRole
        return role == .parent || role == .teacher
    }
    
    // Get classroom for teacher assignments
    private var classroom: Classroom? {
        // For parents, we don't need classroom
        // For teachers, we would need to pass it in or fetch it
        nil // Will be enhanced if needed
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    if isLoading && weakConcepts.isEmpty {
                        loadingView
                    } else if weakConcepts.isEmpty {
                        noWeakAreasView
                    } else {
                        // Weak Areas Analysis
                        weakAreasAnalysisSection
                        
                        // Error Patterns (if any)
                        if !errorPatterns.isEmpty {
                            errorPatternsSection
                        }
                        
                        // AI Recommendation
                        aiRecommendationSection
                        
                        // Generate Button
                        generateSection
                        
                        // Generated Problems Preview
                        if !generatedProblems.isEmpty {
                            generatedPreviewSection
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Smart Practice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                await loadWeakAreas()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .fullScreenCover(isPresented: $showingPracticeSession) {
                PracticeSessionView(
                    problems: generatedProblems,
                    child: child
                )
            }
            .sheet(isPresented: $showingAssignPractice) {
                AssignPracticeView(
                    problems: generatedProblems,
                    sourceType: .weakArea,
                    curriculumCodes: weakConcepts.compactMap { mastery in
                        // Extract curriculum codes if available
                        mastery.curriculumCode
                    },
                    curriculumGradeLevel: child.gradeLevel,
                    targetConcepts: weakConcepts.prefix(5).map { $0.concept },
                    targetChild: child,
                    classroom: classroom,
                    onAssigned: { assignment in
                        dismiss()
                    }
                )
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text("AI-Powered Practice")
                    .font(.title2.bold())
                
                Text("Personalized for \(child.displayName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Analyzing learning patterns...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
    
    // MARK: - No Weak Areas View
    
    private var noWeakAreasView: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.fill")
                .font(.system(size: 50))
                .foregroundColor(.yellow)
            
            Text("Great Job!")
                .font(.title2.bold())
            
            Text("No weak areas detected. \(child.displayName) is doing well across all concepts!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            NavigationLink(destination: PracticeGenerationView(
                child: child,
                concepts: [],
                suggestedDifficulty: .harder
            )) {
                HStack {
                    Image(systemName: "flame.fill")
                    Text("Try Challenge Mode")
                }
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.orange)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Weak Areas Analysis
    
    private var weakAreasAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                    .foregroundColor(.orange)
                Text("Areas to Focus On")
                    .font(.headline)
            }
            
            ForEach(weakConcepts.prefix(5), id: \.id) { mastery in
                WeakConceptCard(mastery: mastery)
            }
        }
    }
    
    // MARK: - Error Patterns Section
    
    private var errorPatternsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Common Mistakes")
                    .font(.headline)
            }
            
            ForEach(errorPatterns.prefix(3), id: \.id) { pattern in
                ErrorPatternCard2(pattern: pattern)
            }
        }
        .padding()
        .background(Color.red.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - AI Recommendation
    
    private var aiRecommendationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("AI Recommendation")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(generateRecommendation())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Recommended focus areas
                HStack(spacing: 8) {
                    ForEach(weakConcepts.prefix(3), id: \.id) { mastery in
                        Text(mastery.concept)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.purple.opacity(0.1))
                            .foregroundColor(.purple)
                            .cornerRadius(8)
                    }
                }
                
                // Recommended difficulty
                HStack {
                    Text("Suggested difficulty:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(recommendedDifficulty.displayName)
                        .font(.caption.bold())
                        .foregroundColor(recommendedDifficulty.color)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.purple.opacity(0.1), .blue.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
    
    // MARK: - Generate Section
    
    private var generateSection: some View {
        VStack(spacing: 12) {
            Button(action: generatePractice) {
                HStack(spacing: 12) {
                    if generationService.isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "sparkles")
                    }
                    
                    Text(generationService.isGenerating ? "Generating..." : "Generate Smart Practice")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: generationService.isGenerating ? [.gray] : [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .disabled(generationService.isGenerating)
            
            if generationService.isGenerating {
                ProgressView(value: generationService.generationProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .purple))
            }
        }
    }
    
    // MARK: - Generated Preview
    
    private var generatedPreviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Practice Ready!")
                    .font(.headline)
                
                Spacer()
                
                Text("\(generatedProblems.count) problems")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Concept distribution
            let conceptCounts = Dictionary(grouping: generatedProblems, by: { $0.concept })
            
            ForEach(Array(conceptCounts.keys), id: \.self) { concept in
                HStack {
                    Text(concept)
                        .font(.subheadline)
                    Spacer()
                    Text("\(conceptCounts[concept]?.count ?? 0) problems")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button(action: { showingPracticeSession = true }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Practice Now")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.green)
                .cornerRadius(16)
            }
            
            // Assign Practice Button (for parents/teachers)
            if canAssign {
                Button(action: { showingAssignPractice = true }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Assign to \(child.displayName)")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
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
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.3), lineWidth: 2)
        )
    }
    
    // MARK: - Helper Methods
    
    private var recommendedDifficulty: PracticeDifficulty {
        guard let weakest = weakConcepts.first else { return .similar }
        return PracticeDifficulty.recommended(forMasteryPercentage: weakest.masteryPercentage)
    }
    
    private func generateRecommendation() -> String {
        guard let weakest = weakConcepts.first else {
            return "Great job! Keep practicing to maintain your skills."
        }
        
        if weakest.masteryPercentage < 40 {
            return "Focus on building foundational understanding with easier problems. Take your time and use hints when needed."
        } else if weakest.masteryPercentage < 60 {
            return "You're making progress! Practice with similar difficulty problems to strengthen these concepts."
        } else {
            return "Almost there! A bit more practice will help solidify these skills."
        }
    }
    
    private func loadWeakAreas() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch concept mastery
            let allMastery = try await queryService.fetchConceptMastery(
                studentId: child.userId,
                classroomId: classroomId
            )
            
            // Filter to weak areas (< 70%)
            weakConcepts = allMastery
                .filter { $0.masteryPercentage < 70 }
                .sorted { $0.masteryPercentage < $1.masteryPercentage }
            
            // Fetch error patterns
            errorPatterns = try await queryService.fetchErrorPatterns(
                studentId: child.userId,
                classroomId: classroomId
            )
            .filter { !$0.isResolved }
            .sorted { $0.occurrenceCount > $1.occurrenceCount }
            
        } catch {
            print("âš ï¸ Failed to load weak areas: \(error)")
        }
    }
    
    private func generatePractice() {
        guard let userId = awsService.currentUserProfile?.userId else {
            errorMessage = "User not found"
            return
        }
        
        Task {
            do {
                generatedProblems = try await generationService.generateForWeakAreas(
                    studentId: child.userId,
                    classroomId: classroomId,
                    count: 10,
                    userId: userId
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Supporting Views

struct WeakConceptCard: View {
    let mastery: ConceptMastery
    
    var body: some View {
        HStack(spacing: 12) {
            // Progress Ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                    .frame(width: 48, height: 48)
                
                Circle()
                    .trim(from: 0, to: mastery.masteryPercentage / 100)
                    .stroke(progressColor, lineWidth: 4)
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(mastery.masteryPercentage))%")
                    .font(.caption.bold())
                    .foregroundColor(progressColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(mastery.concept)
                    .font(.subheadline.bold())
                
                HStack(spacing: 8) {
                    Label("\(mastery.totalAttempts) attempts", systemImage: "number")
                    
                    if let trend = TrendIndicatorType(rawValue: mastery.trend) {
                        Label(trend.displayName, systemImage: trend.icon)
                            .foregroundColor(trend.color)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var progressColor: Color {
        if mastery.masteryPercentage >= 60 { return .yellow }
        if mastery.masteryPercentage >= 40 { return .orange }
        return .red
    }
}

struct ErrorPatternCard2: View {
    let pattern: ErrorPattern
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(severityColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(pattern.errorType)
                    .font(.subheadline.bold())
                
                Text(pattern.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text("Occurred \(pattern.occurrenceCount) times")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var severityColor: Color {
        switch pattern.severity {
        case "high": return .red
        case "medium": return .orange
        default: return .yellow
        }
    }
}

enum TrendIndicatorType: String {
    case improving
    case stable
    case declining
    
    var displayName: String {
        switch self {
        case .improving: return "Improving"
        case .stable: return "Stable"
        case .declining: return "Declining"
        }
    }
    
    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }
    
    var color: Color {
        switch self {
        case .improving: return .green
        case .stable: return .blue
        case .declining: return .red
        }
    }
}
