//
//  AIRecommendationsView.swift
//  PeaTutorApp
//
//  Sprint 7.2 Phase 5: AI Recommendations View
//  Intelligent, actionable recommendations for teachers based on student analytics
//

import SwiftUI
import Amplify

// MARK: - Main AI Recommendations View

struct AIRecommendationsView: View {
    let studentSummary: StudentAnalyticsSummary?
    let errorPatterns: [ErrorPattern]
    
    @State private var recommendations: [Recommendation] = []
    @State private var isGenerating = false
    @State private var selectedCategory: RecommendationCategory?
    
    var body: some View {
        Group {
            if isGenerating {
                loadingView
            } else if recommendations.isEmpty {
                emptyState
            } else {
                recommendationsContent
            }
        }
        .onAppear {
            generateRecommendations()
        }
    }
    
    // MARK: - Recommendations Content
    
    private var recommendationsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection
            
            // Category filter
            categoryFilterSection
            
            // Recommendations list
            recommendationsList
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AI Recommendations")
                .font(.title3.bold())
            
            if let summary = studentSummary {
                HStack(spacing: 12) {
                    // Overall insight
                    InsightBadge(
                        icon: summary.overallProgress >= 70 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
                        text: summary.overallProgress >= 70 ? "On Track" : "Needs Support",
                        color: summary.overallProgress >= 70 ? .green : .orange
                    )
                    
                    // Recommendation count
                    InsightBadge(
                        icon: "lightbulb.fill",
                        text: "\(recommendations.count) Recommendations",
                        color: .blue
                    )
                }
            }
        }
    }
    
    // MARK: - Category Filter
    
    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryButton(
                    category: nil,
                    isSelected: selectedCategory == nil,
                    count: recommendations.count
                ) {
                    withAnimation {
                        selectedCategory = nil
                    }
                }
                
                ForEach(RecommendationCategory.allCases, id: \.self) { category in
                    let count = recommendations.filter { $0.category == category }.count
                    if count > 0 {
                        CategoryButton(
                            category: category,
                            isSelected: selectedCategory == category,
                            count: count
                        ) {
                            withAnimation {
                                selectedCategory = category
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Recommendations List
    
    private var recommendationsList: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredRecommendations) { recommendation in
                RecommendationCard(recommendation: recommendation)
            }
        }
    }
    
    private var filteredRecommendations: [Recommendation] {
        if let category = selectedCategory {
            return recommendations.filter { $0.category == category }
        }
        return recommendations
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Generating personalized recommendations...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        ContentUnavailableView(
            "Insufficient Data",
            systemImage: "chart.bar.doc.horizontal",
            description: Text("Complete more homework assignments to receive personalized recommendations")
        )
        .frame(height: 300)
    }
    
    // MARK: - Generate Recommendations
    
    private func generateRecommendations() {
        guard let summary = studentSummary else {
            return
        }
        
        isGenerating = true
        
        // Simulate AI processing delay for realistic UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            var generated: [Recommendation] = []
            
            // 1. Focus Area Recommendations (Needs Work Concepts)
            generated.append(contentsOf: generateFocusAreaRecommendations(summary: summary))
            
            // 2. Error Pattern Interventions
            generated.append(contentsOf: generateErrorInterventions())
            
            // 3. Quick Wins (Nearly Mastered Concepts)
            generated.append(contentsOf: generateQuickWins(summary: summary))
            
            // 4. Leverage Strengths
            generated.append(contentsOf: generateStrengthLeveraging(summary: summary))
            
            // 5. Next Concepts (Progression)
            generated.append(contentsOf: generateNextConcepts(summary: summary))
            
            // 6. Parent Support Suggestions
            generated.append(contentsOf: generateParentSupport(summary: summary))
            
            // Sort by priority
            generated.sort { $0.priority.order < $1.priority.order }
            
            withAnimation {
                recommendations = generated
                isGenerating = false
            }
        }
    }
    
    // MARK: - Recommendation Generators
    
    private func generateFocusAreaRecommendations(summary: StudentAnalyticsSummary) -> [Recommendation] {
        var recs: [Recommendation] = []
        
        // Critical concepts (needs work)
        for concept in summary.needsWorkConcepts.prefix(3) {
            recs.append(Recommendation(
                id: UUID().uuidString,
                category: .focusAreas,
                priority: .high,
                title: "Strengthen \(concept) Skills",
                description: "This concept requires immediate attention with mastery below 60%. Dedicate focused practice sessions to build foundational understanding.",
                actionItems: [
                    "Assign 5-10 practice problems daily",
                    "Review prerequisite concepts if struggling",
                    "Use visual aids and manipulatives",
                    "Schedule one-on-one support if needed"
                ],
                estimatedImpact: "High - Core skill for grade level",
                timeframe: "1-2 weeks"
            ))
        }
        
        return recs
    }
    
    private func generateErrorInterventions() -> [Recommendation] {
        var recs: [Recommendation] = []
        
        // High severity errors
        let highSeverityErrors = errorPatterns.filter { $0.severityLevel == .high && $0.isActive }
        
        for error in highSeverityErrors.prefix(2) {
            recs.append(Recommendation(
                id: UUID().uuidString,
                category: .interventions,
                priority: .high,
                title: "Address \(error.errorType)",
                description: error.description,
                actionItems: error.remediation?.components(separatedBy: "\n").filter { !$0.isEmpty } ?? [
                    "Review the concept with student",
                    "Provide targeted practice",
                    "Monitor progress closely"
                ],
                estimatedImpact: "High - Recurring pattern (\(error.occurrenceCount)x)",
                timeframe: "This week"
            ))
        }
        
        return recs
    }
    
    private func generateQuickWins(summary: StudentAnalyticsSummary) -> [Recommendation] {
        var recs: [Recommendation] = []
        
        // Developing concepts (60-79%) - close to mastery
        for concept in summary.developingConcepts.prefix(2) {
            recs.append(Recommendation(
                id: UUID().uuidString,
                category: .quickWins,
                priority: .medium,
                title: "Push \(concept) to Mastery",
                description: "Student is close to mastering this concept (60-79%). A few focused sessions could boost confidence and solidify understanding.",
                actionItems: [
                    "Assign 3-5 challenging problems",
                    "Provide positive reinforcement",
                    "Connect to real-world applications",
                    "Celebrate progress when mastered"
                ],
                estimatedImpact: "Medium - Quick confidence boost",
                timeframe: "3-5 days"
            ))
        }
        
        return recs
    }
    
    private func generateStrengthLeveraging(summary: StudentAnalyticsSummary) -> [Recommendation] {
        var recs: [Recommendation] = []
        
        // Use mastered concepts to help with weak ones
        if !summary.masteredConcepts.isEmpty && !summary.needsWorkConcepts.isEmpty {
            let strongConcept = summary.masteredConcepts.first!
            let weakConcept = summary.needsWorkConcepts.first!
            
            recs.append(Recommendation(
                id: UUID().uuidString,
                category: .leverageStrengths,
                priority: .medium,
                title: "Use \(strongConcept) to Teach \(weakConcept)",
                description: "Student excels at \(strongConcept). Create connections between this strength and struggling areas to build confidence and understanding.",
                actionItems: [
                    "Design problems that combine both concepts",
                    "Start with \(strongConcept) to build confidence",
                    "Gradually introduce \(weakConcept) elements",
                    "Praise the connection they make"
                ],
                estimatedImpact: "Medium - Builds on existing knowledge",
                timeframe: "Ongoing"
            ))
        }
        
        return recs
    }
    
    private func generateNextConcepts(summary: StudentAnalyticsSummary) -> [Recommendation] {
        var recs: [Recommendation] = []
        
        // Suggest progression if student is doing well
        if summary.overallProgress >= 70 && summary.masteredConcepts.count >= 3 {
            recs.append(Recommendation(
                id: UUID().uuidString,
                category: .nextSteps,
                priority: .low,
                title: "Ready for Advanced Challenges",
                description: "Strong overall performance (\(Int(summary.overallProgress))%) indicates readiness for more complex problems and new concepts.",
                actionItems: [
                    "Introduce grade-level+ enrichment problems",
                    "Assign multi-step word problems",
                    "Challenge with real-world applications",
                    "Consider peer teaching opportunities"
                ],
                estimatedImpact: "Medium - Prevents boredom, maintains engagement",
                timeframe: "Next unit"
            ))
        }
        
        return recs
    }
    
    private func generateParentSupport(summary: StudentAnalyticsSummary) -> [Recommendation] {
        var recs: [Recommendation] = []
        
        // Suggest parent involvement based on needs
        if !summary.needsWorkConcepts.isEmpty {
            let concept = summary.needsWorkConcepts.first!
            
            recs.append(Recommendation(
                id: UUID().uuidString,
                category: .parentSupport,
                priority: .medium,
                title: "Parent Support for \(concept)",
                description: "Engage parents to reinforce \(concept) at home through everyday activities and practice.",
                actionItems: [
                    "Share simple practice activities parents can do",
                    "Suggest real-world examples (cooking, shopping, etc.)",
                    "Provide 5-10 minute daily practice worksheets",
                    "Encourage positive reinforcement, not pressure"
                ],
                estimatedImpact: "Medium - Reinforces classroom learning",
                timeframe: "Ongoing"
            ))
        }
        
        return recs
    }
}

// MARK: - Recommendation Model

struct Recommendation: Identifiable {
    let id: String
    let category: RecommendationCategory
    let priority: RecommendationPriority
    let title: String
    let description: String
    let actionItems: [String]
    let estimatedImpact: String
    let timeframe: String
}

// MARK: - Recommendation Category

enum RecommendationCategory: String, CaseIterable {
    case focusAreas = "Focus Areas"
    case interventions = "Interventions"
    case quickWins = "Quick Wins"
    case leverageStrengths = "Leverage Strengths"
    case nextSteps = "Next Steps"
    case parentSupport = "Parent Support"
    
    var icon: String {
        switch self {
        case .focusAreas:
            return "target"
        case .interventions:
            return "bandage.fill"
        case .quickWins:
            return "bolt.fill"
        case .leverageStrengths:
            return "star.fill"
        case .nextSteps:
            return "arrow.forward.circle.fill"
        case .parentSupport:
            return "person.2.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .focusAreas:
            return .red
        case .interventions:
            return .orange
        case .quickWins:
            return .green
        case .leverageStrengths:
            return .purple
        case .nextSteps:
            return .blue
        case .parentSupport:
            return .pink
        }
    }
}

// MARK: - Recommendation Priority

enum RecommendationPriority: String {
    case high = "High Priority"
    case medium = "Medium Priority"
    case low = "Low Priority"
    
    var order: Int {
        switch self {
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }
    
    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .high: return "exclamationmark.3"
        case .medium: return "exclamationmark.2"
        case .low: return "exclamationmark"
        }
    }
}

// MARK: - Recommendation Card

struct RecommendationCard: View {
    let recommendation: Recommendation
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: { withAnimation(.spring(response: 0.3)) { isExpanded.toggle() } }) {
                VStack(alignment: .leading, spacing: 12) {
                    // Title row
                    HStack(alignment: .top, spacing: 12) {
                        // Category icon
                        Image(systemName: recommendation.category.icon)
                            .font(.title2)
                            .foregroundColor(recommendation.category.color)
                            .frame(width: 40)
                        
                        // Title and description
                        VStack(alignment: .leading, spacing: 6) {
                            Text(recommendation.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(recommendation.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(isExpanded ? nil : 2)
                        }
                        
                        Spacer()
                        
                        // Expand icon
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                    }
                    
                    // Badges
                    HStack(spacing: 8) {
                        // Priority badge
                        PriorityBadge(priority: recommendation.priority)
                        
                        // Category badge
                        CategoryTag(text: recommendation.category.rawValue, color: recommendation.category.color)
                        
                        Spacer()
                        
                        // Timeframe
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text(recommendation.timeframe)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded content
            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(recommendation.category.color.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Expanded Content
    
    @ViewBuilder
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 16) {
                // Action items
                RecommendationSection(
                    icon: "list.bullet.clipboard.fill",
                    title: "Action Items",
                    iconColor: .blue
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(recommendation.actionItems.enumerated()), id: \.offset) { index, item in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(index + 1).")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.blue)
                                
                                Text(item)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Impact & Timeframe
                HStack(spacing: 16) {
                    RecommendationSection(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Expected Impact",
                        iconColor: .green
                    ) {
                        Text(recommendation.estimatedImpact)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

// MARK: - Recommendation Section

struct RecommendationSection<Content: View>: View {
    let icon: String
    let title: String
    let iconColor: Color
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.subheadline.bold())
            }
            
            content()
        }
    }
}

// MARK: - Priority Badge

struct PriorityBadge: View {
    let priority: RecommendationPriority
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: priority.icon)
                .font(.caption2)
            Text(priority.rawValue)
                .font(.caption)
        }
        .foregroundColor(priority.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(priority.color.opacity(0.1))
        .cornerRadius(6)
    }
}

// MARK: - Category Tag

struct CategoryTag: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .cornerRadius(6)
    }
}

// MARK: - Insight Badge

struct InsightBadge: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Category Button

struct CategoryButton: View {
    let category: RecommendationCategory?
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let category = category {
                    Image(systemName: category.icon)
                        .font(.caption)
                    Text(category.rawValue)
                        .font(.subheadline)
                } else {
                    Text("All")
                        .font(.subheadline)
                }
                
                Text("(\(count))")
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? categoryColor : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var categoryColor: Color {
        category?.color ?? .blue
    }
}
