//
//  ParentAnalyticsOverviewView.swift
//  PeaTutorApp
//
//  Sprint 7.3 Phase 1: Parent Analytics Overview Dashboard
//  Multi-child analytics view with cross-child comparison and weekly summary
//

import SwiftUI
import Amplify

struct ParentAnalyticsOverviewView: View {
    @StateObject private var awsService = AWSService.shared
    
    // Data state
    @State private var children: [UserProfile] = []
    @State private var childAnalytics: [String: ChildAnalyticsData] = [:] // childId -> analytics
    @State private var weeklyActivity: [DailyActivity] = []
    
    // UI state
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedTimeframe: Timeframe = .week
    
    enum Timeframe: String, CaseIterable {
        case week = "This Week"
        case month = "This Month"
        case allTime = "All Time"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    loadingView
                } else if children.isEmpty {
                    emptyStateView
                } else {
                    VStack(spacing: 24) {
                        // Overall Family Summary
                        familySummaryCard
                        
                        // Weekly Activity Chart
                        weeklyActivitySection
                        
                        // Children Comparison
                        childrenComparisonSection
                        
                        // Individual Child Cards
                        individualChildrenSection
                        
                        // Attention Needed Section
                        if hasChildrenNeedingAttention {
                            attentionNeededSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Family Progress")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(Timeframe.allCases, id: \.self) { timeframe in
                            Button(action: { selectedTimeframe = timeframe }) {
                                HStack {
                                    Text(timeframe.rawValue)
                                    if selectedTimeframe == timeframe {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedTimeframe.rawValue)
                                .font(.subheadline)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .task {
                await loadAllAnalytics()
            }
            .refreshable {
                await loadAllAnalytics()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var hasChildrenNeedingAttention: Bool {
        childAnalytics.values.contains { $0.overallProgress < 60 || $0.needsWorkCount > 2 }
    }
    
    private var familyAverageProgress: Double {
        guard !childAnalytics.isEmpty else { return 0 }
        let total = childAnalytics.values.reduce(0.0) { $0 + $1.overallProgress }
        return total / Double(childAnalytics.count)
    }
    
    private var totalMasteredConcepts: Int {
        childAnalytics.values.reduce(0) { $0 + $1.masteredCount }
    }
    
    private var totalHomeworkCompleted: Int {
        childAnalytics.values.reduce(0) { $0 + $1.homeworkCompleted }
    }
    
    private var totalHomeworkAssigned: Int {
        childAnalytics.values.reduce(0) { $0 + $1.homeworkAssigned }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading family progress...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 400)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Children Linked")
                .font(.title2.bold())
            
            Text("Link your children's accounts to see their progress here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    // MARK: - Family Summary Card
    
    private var familySummaryCard: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Family Overview")
                        .font(.title2.bold())
                    Text("\(children.count) \(children.count == 1 ? "child" : "children") tracked")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Family Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(familyAverageProgress / 100))
                        .stroke(
                            familyProgressGradient,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text("\(Int(familyAverageProgress))%")
                            .font(.headline.bold())
                        Text("avg")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Stats Row
            HStack(spacing: 0) {
                FamilyStatItem(
                    icon: "checkmark.seal.fill",
                    value: "\(totalMasteredConcepts)",
                    label: "Mastered",
                    color: .green
                )
                
                Divider()
                    .frame(height: 40)
                
                FamilyStatItem(
                    icon: "doc.text.fill",
                    value: "\(totalHomeworkCompleted)/\(totalHomeworkAssigned)",
                    label: "Homework",
                    color: .blue
                )
                
                Divider()
                    .frame(height: 40)
                
                FamilyStatItem(
                    icon: "person.2.fill",
                    value: "\(children.count)",
                    label: "Children",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    private var familyProgressGradient: LinearGradient {
        let colors: [Color] = familyAverageProgress >= 70 ? [.green, .green.opacity(0.7)] :
                              familyAverageProgress >= 50 ? [.orange, .yellow] :
                              [.red, .orange]
        return LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
    }
    
    // MARK: - Weekly Activity Section
    
    private var weeklyActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Activity")
                .font(.headline)
            
            if weeklyActivity.isEmpty {
                Text("No activity this week")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                // Simple bar chart
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(weeklyActivity, id: \.date) { day in
                        VStack(spacing: 4) {
                            // Bar
                            RoundedRectangle(cornerRadius: 4)
                                .fill(day.hasActivity ? Color.purple : Color.gray.opacity(0.3))
                                .frame(width: 36, height: max(20, CGFloat(day.questionsCompleted) * 3))
                            
                            // Day label
                            Text(day.dayAbbreviation)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                
                // Legend
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 8, height: 8)
                        Text("Active")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                        Text("No Activity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Children Comparison Section
    
    private var childrenComparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress Comparison")
                .font(.headline)
            
            if children.count < 2 {
                Text("Add more children to compare progress")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                // Comparison bars
                VStack(spacing: 12) {
                    ForEach(children.sorted {
                        (childAnalytics[$0.userId]?.overallProgress ?? 0) > (childAnalytics[$1.userId]?.overallProgress ?? 0)
                    }, id: \.userId) { child in
                        if let analytics = childAnalytics[child.userId] {
                            ChildComparisonBar(
                                name: child.displayName,
                                progress: analytics.overallProgress,
                                masteredCount: analytics.masteredCount,
                                color: colorForChild(child.userId)
                            )
                        }
                    }
                }
                
                // Comparison insights
                if let insight = generateComparisonInsight() {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text(insight)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Individual Children Section
    
    private var individualChildrenSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Individual Progress")
                .font(.headline)
            
            ForEach(children, id: \.userId) { child in
                if let analytics = childAnalytics[child.userId] {
                    NavigationLink(destination: ParentChildAnalyticsView(
                        child: child,
                        classroom: nil // Will load in the detail view
                    )) {
                        ChildProgressCard(
                            child: child,
                            analytics: analytics,
                            accentColor: colorForChild(child.userId)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Attention Needed Section
    
    private var attentionNeededSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Needs Attention")
                    .font(.headline)
            }
            
            ForEach(childrenNeedingAttention, id: \.userId) { child in
                if let analytics = childAnalytics[child.userId] {
                    NavigationLink(destination: ParentChildAnalyticsView(
                        child: child,
                        classroom: nil
                    )) {
                        AttentionCard(child: child, analytics: analytics)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(16)
    }
    
    private var childrenNeedingAttention: [UserProfile] {
        children.filter { child in
            guard let analytics = childAnalytics[child.userId] else { return false }
            return analytics.overallProgress < 60 || analytics.needsWorkCount > 2
        }
    }
    
    // MARK: - Helper Methods
    
    private func colorForChild(_ userId: String) -> Color {
        let colors: [Color] = [.blue, .purple, .green, .orange, .pink]
        if let index = children.firstIndex(where: { $0.userId == userId }) {
            return colors[index % colors.count]
        }
        return .blue
    }
    
    private func generateComparisonInsight() -> String? {
        guard children.count >= 2 else { return nil }
        
        let sorted = children.compactMap { child -> (UserProfile, Double)? in
            guard let analytics = childAnalytics[child.userId] else { return nil }
            return (child, analytics.overallProgress)
        }.sorted { $0.1 > $1.1 }
        
        guard sorted.count >= 2 else { return nil }
        
        let top = sorted[0]
        let bottom = sorted[sorted.count - 1]
        let difference = top.1 - bottom.1
        
        if difference < 10 {
            return "Great news! All children are progressing at similar rates."
        } else if difference < 25 {
            return "\(top.0.displayName) is slightly ahead. Consider some extra practice time with \(bottom.0.displayName)."
        } else {
            return "\(bottom.0.displayName) could use some focused attention. Check the 'How to Help' section for tips."
        }
    }
    
    // MARK: - Load Data
    
    private func loadAllAnalytics() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch linked children
            let linkedChildren = try await awsService.fetchLinkedChildren()
            
            // Load analytics for each child
            var analyticsMap: [String: ChildAnalyticsData] = [:]
            
            for child in linkedChildren {
                let analytics = try await loadChildAnalytics(studentId: child.userId)
                analyticsMap[child.userId] = analytics
            }
            
            // Generate weekly activity
            let activity = generateWeeklyActivity(children: linkedChildren)
            
            await MainActor.run {
                self.children = linkedChildren
                self.childAnalytics = analyticsMap
                self.weeklyActivity = activity
            }
            
        } catch {
            errorMessage = "Failed to load analytics: \(error.localizedDescription)"
            print("❌ Parent analytics overview error: \(error)")
        }
    }
    
    private func loadChildAnalytics(studentId: String) async throws -> ChildAnalyticsData {
        // Get concept mastery
        let allMastery = try await Amplify.DataStore.query(ConceptMastery.self)
        let studentMastery = allMastery.filter { $0.studentId == studentId }
        
        // Calculate overall progress
        let overallProgress = studentMastery.isEmpty ? 0 :
            studentMastery.reduce(0.0) { $0 + $1.masteryPercentage } / Double(studentMastery.count)
        
        // Count mastered and needs work
        let masteredCount = studentMastery.filter { $0.masteryPercentage >= 80 }.count
        let needsWorkCount = studentMastery.filter { $0.masteryPercentage < 60 }.count
        
        // Get student progress
        let allProgress = try await Amplify.DataStore.query(StudentProgress.self)
        let studentProgress = allProgress.first { $0.studentId == studentId }
        
        // Get error patterns
        let allErrors = try await Amplify.DataStore.query(ErrorPattern.self)
        let activeErrors = allErrors.filter { $0.studentId == studentId && $0.isActive }
        
        // Get top strength and weakness
        let sortedMastery = studentMastery.sorted { $0.masteryPercentage > $1.masteryPercentage }
        let topStrength = sortedMastery.first?.concept
        let topWeakness = sortedMastery.last?.concept
        
        return ChildAnalyticsData(
            overallProgress: overallProgress,
            masteredCount: masteredCount,
            needsWorkCount: needsWorkCount,
            homeworkCompleted: studentProgress?.totalHomeworkCompleted ?? 0,
            homeworkAssigned: studentProgress?.totalHomeworkAssigned ?? 0,
            currentStreak: studentProgress?.currentStreak ?? 0,
            activeErrorCount: activeErrors.count,
            topStrength: topStrength,
            topWeakness: topWeakness
        )
    }
    
    private func generateWeeklyActivity(children: [UserProfile]) -> [DailyActivity] {
        let calendar = Calendar.current
        let today = Date()
        
        // Generate last 7 days
        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            // For now, generate sample data - in production, query actual submissions
            let hasActivity = daysAgo < 5 && daysAgo != 2 // Sample: activity on most days
            let questionsCompleted = hasActivity ? Int.random(in: 5...25) : 0
            
            return DailyActivity(
                date: date,
                questionsCompleted: questionsCompleted,
                homeworkSubmitted: hasActivity ? Int.random(in: 0...2) : 0
            )
        }
    }
}

// MARK: - Supporting Types

struct ChildAnalyticsData {
    let overallProgress: Double
    let masteredCount: Int
    let needsWorkCount: Int
    let homeworkCompleted: Int
    let homeworkAssigned: Int
    let currentStreak: Int
    let activeErrorCount: Int
    let topStrength: String?
    let topWeakness: String?
}

struct DailyActivity {
    let date: Date
    let questionsCompleted: Int
    let homeworkSubmitted: Int
    
    var hasActivity: Bool {
        questionsCompleted > 0 || homeworkSubmitted > 0
    }
    
    var dayAbbreviation: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - Family Stat Item

struct FamilyStatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline.bold())
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Child Comparison Bar

struct ChildComparisonBar: View {
    let name: String
    let progress: Double
    let masteredCount: Int
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
                        .fill(Color.gray.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(progress / 100))
                }
            }
            .frame(height: 8)
            
            Text("\(masteredCount) concepts mastered")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Child Progress Card

struct ChildProgressCard: View {
    let child: UserProfile
    let analytics: ChildAnalyticsData
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar with progress ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                    .frame(width: 56, height: 56)
                
                Circle()
                    .trim(from: 0, to: CGFloat(analytics.overallProgress / 100))
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))
                
                Circle()
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(child.initials)
                            .font(.subheadline.bold())
                            .foregroundColor(accentColor)
                    )
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(child.displayName)
                    .font(.headline)
                
                HStack(spacing: 12) {
                    Label("\(analytics.masteredCount) mastered", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    if analytics.currentStreak > 0 {
                        Label("\(analytics.currentStreak) day streak", systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                if let strength = analytics.topStrength {
                    Text("Strong in: \(strength)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Progress
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(analytics.overallProgress))%")
                    .font(.title3.bold())
                    .foregroundColor(accentColor)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Attention Card

struct AttentionCard: View {
    let child: UserProfile
    let analytics: ChildAnalyticsData
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.orange.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(child.initials)
                        .font(.subheadline.bold())
                        .foregroundColor(.orange)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(child.displayName)
                    .font(.subheadline.bold())
                
                Text(attentionMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
    
    private var attentionMessage: String {
        if analytics.overallProgress < 50 {
            return "Progress is below 50% - needs support"
        } else if analytics.needsWorkCount > 2 {
            return "\(analytics.needsWorkCount) topics need practice"
        } else if let weakness = analytics.topWeakness {
            return "Struggling with \(weakness)"
        } else {
            return "Could use some extra help"
        }
    }
}
