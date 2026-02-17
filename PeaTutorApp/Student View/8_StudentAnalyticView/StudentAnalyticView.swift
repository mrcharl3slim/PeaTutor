//
//  StudentAnalyticsView.swift
//  PeaTutorApp
//
//  Sprint 7.2: Teacher Analytics Dashboard
//  Main view for displaying comprehensive student analytics
//

import SwiftUI
import Amplify

struct StudentAnalyticsView: View {
    let studentId: String
    let classroom: Classroom?
    let studentProfile: UserProfile?
    
    @StateObject private var queryService = AnalyticsQueryService.shared
    @StateObject private var analyticsService = AnalyticsService.shared
    
    // Data state
    @State private var conceptMastery: [ConceptMastery] = []
    @State private var errorPatterns: [ErrorPattern] = []
    @State private var cognitiveProfile: CognitiveProfile?
    @State private var studentSummary: StudentAnalyticsSummary?
    
    // UI state
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedTab: AnalyticsTab = .conceptMastery
    
    enum AnalyticsTab: String, CaseIterable {
        case conceptMastery = "Concepts"
        case cognitiveSkills = "Skills"
        case errorPatterns = "Errors"
        case recommendations = "Insights"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Student Header
                studentHeaderCard
                
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
        .navigationTitle("Student Analytics")
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
    
    // MARK: - Student Header Card
    
    private var studentHeaderCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .overlay(
                        Text(studentProfile?.initials ?? "?")
                            .font(.title.bold())
                            .foregroundColor(.white)
                    )
                
                // Student Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(studentProfile?.displayName ?? "Unknown Student")
                        .font(.title2.bold())
                    
                    HStack(spacing: 12) {
                        if let gradeLevel = studentProfile?.gradeLevel {
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
                }
                
                Spacer()
                
                // Overall Progress
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Overall")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(studentSummary?.overallProgress ?? 0))%")
                        .font(.title.bold())
                        .foregroundColor(progressColor(studentSummary?.overallProgress ?? 0))
                    
                    if let summary = studentSummary, summary.overallProgress >= 70 {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right")
                                .font(.caption2)
                            Text("On Track")
                                .font(.caption2)
                        }
                        .foregroundColor(.green)
                    }
                }
            }
            
            // Quick Stats
            HStack(spacing: 12) {
                QuickStatCard(
                    icon: "checkmark.circle.fill",
                    value: "\(studentSummary?.masteredConcepts.count ?? 0)",
                    label: "Mastered",
                    color: .green
                )
                
                QuickStatCard(
                    icon: "arrow.triangle.2.circlepath",
                    value: "\(studentSummary?.totalQuestionsAttempted ?? 0)",
                    label: "Attempted",
                    color: .blue
                )
                
                QuickStatCard(
                    icon: "percent",
                    value: "\(Int(studentSummary?.overallAccuracy ?? 0))%",
                    label: "Accuracy",
                    color: .orange
                )
                
                QuickStatCard(
                    icon: "exclamationmark.triangle.fill",
                    value: "\(studentSummary?.highSeverityErrorCount ?? 0)",
                    label: "High Errors",
                    color: .red
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AnalyticsTab.allCases, id: \.self) { tab in
                    TabButton(
                        title: tab.rawValue,
                        icon: tabIcon(for: tab),
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
        case .conceptMastery:
            ConceptMasteryGridView(
                concepts: conceptMastery,
                studentId: studentId,
                classroomId: classroom?.id
            )
            
        case .cognitiveSkills:
            if let profile = cognitiveProfile {
                CognitiveSkillsRadarView(profile: profile)
            } else {
                emptyStateView(
                    icon: "chart.pie",
                    title: "No Skills Data",
                    message: "Complete more homework to see cognitive skills profile"
                )
            }
            
        case .errorPatterns:
            ErrorPatternsListView(
                errors: errorPatterns,
                studentId: studentId,
                classroomId: classroom?.id
            )
            
        case .recommendations:
            AIRecommendationsView(
                studentSummary: studentSummary,
                errorPatterns: errorPatterns
            )
        }
    }
    
    // MARK: - Loading & Empty States
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading analytics...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
    }
    
    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        ContentUnavailableView(
            title,
            systemImage: icon,
            description: Text(message)
        )
        .frame(height: 300)
    }
    
    // MARK: - Helper Methods
    
    private func loadAnalytics() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch all analytics data in parallel
            async let concepts = queryService.fetchConceptMastery(
                studentId: studentId,
                classroomId: classroom?.id
            )
            
            async let errors = queryService.fetchErrorPatterns(
                studentId: studentId,
                classroomId: classroom?.id
            )
            
            async let profile = queryService.calculateCognitiveProfile(
                studentId: studentId,
                classroomId: classroom?.id
            )
            
            async let summary = queryService.fetchStudentSummary(
                studentId: studentId,
                classroomId: classroom?.id
            )
            
            let (fetchedConcepts, fetchedErrors, fetchedProfile, fetchedSummary) = try await (
                concepts,
                errors,
                profile,
                summary
            )
            
            await MainActor.run {
                self.conceptMastery = fetchedConcepts
                self.errorPatterns = fetchedErrors
                self.cognitiveProfile = fetchedProfile
                self.studentSummary = fetchedSummary
            }
            
            print("✅ Analytics loaded: \(fetchedConcepts.count) concepts, \(fetchedErrors.count) errors")
            
        } catch {
            errorMessage = "Failed to load analytics: \(error.localizedDescription)"
            print("❌ Analytics error: \(error)")
        }
    }
    
    private func tabIcon(for tab: AnalyticsTab) -> String {
        switch tab {
        case .conceptMastery:
            return "chart.bar.fill"
        case .cognitiveSkills:
            return "brain.head.profile"
        case .errorPatterns:
            return "exclamationmark.triangle.fill"
        case .recommendations:
            return "lightbulb.fill"
        }
    }
    
    private func progressColor(_ progress: Double) -> Color {
        switch progress {
        case 80...100:
            return .green
        case 60..<80:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Supporting Views

struct TabButton: View {
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
                    .fill(isSelected ? Color.blue : Color(.secondarySystemBackground))
            )
        }
    }
}
