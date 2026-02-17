//
//  ParentDashboardView.swift
//  PeaTutorApp
//
//  Sprint 7.3: Updated with Parent Analytics Integration
//

import SwiftUI
import Amplify

struct ParentDashboardView: View {
    @StateObject private var awsService = AWSService.shared
    @State private var children: [UserProfile] = []
    @State private var childrenClassrooms: [String: [Classroom]] = [:] // childId -> classrooms
    @State private var childrenProgress: [String: ChildProgressSummary] = [:] // childId -> summary
    @State private var isLoading = false
    @State private var showLinkChild = false
    @State private var errorMessage: String?
    @State private var selectedChild: UserProfile?
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView("Loading...")
                } else if children.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Welcome Header
                            welcomeHeader
                            
                            // Quick Actions
                            //quickActionsSection
                            
                            // Learning Alerts (if any child needs attention)
                            /*if hasChildNeedingAttention {
                                learningAlertsSection
                            }*/
                            
                            // Children List
                            childrenSection
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Children")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showLinkChild = true }) {
                        Label("Link Child", systemImage: "plus.circle.fill")
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    profileButton
                }
            }
            .sheet(isPresented: $showLinkChild) {
                LinkChildView(onChildLinked: loadChildren)
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .task {
                await loadChildren()
            }
            .refreshable {
                await loadChildren()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var hasChildNeedingAttention: Bool {
        childrenProgress.values.contains { summary in
            summary.overallProgress < 60 || summary.needsWorkCount > 2
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.2.and.child.holdinghands")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)
            
            Text("No Children Linked")
                .font(.title2.bold())
            
            Text("Link to your child's account to monitor their progress")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: { showLinkChild = true }) {
                Label("Link Child Account", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: 250)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .padding(40)
    }
    
    // MARK: - Welcome Header
    private var welcomeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Parent Dashboard")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let profile = awsService.currentUserProfile {
                    Text(profile.displayName)
                        .font(.title2.bold())
                }
            }
            
            Spacer()
            
            // Quick Stats
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(children.count)")
                    .font(.title.bold())
                Text(children.count == 1 ? "Child" : "Children")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.title3.bold())
            
            // First row of actions
            HStack(spacing: 12) {
                // Homework Monitoring
                NavigationLink(destination: ParentHomeworkView()) {
                    QuickActionCard(
                        title: "Homework",
                        icon: "doc.text.fill",
                        color: .orange,
                        description: "Monitor assignments"
                    )
                }
                
                // Progress Tracking - Links to overview if multiple children, otherwise to single child
                if children.count > 1 {
                    NavigationLink(destination: ParentAnalyticsOverviewView()) {
                        QuickActionCard(
                            title: "Progress",
                            icon: "chart.line.uptrend.xyaxis",
                            color: .green,
                            description: "Family overview"
                        )
                    }
                } else if let firstChild = children.first {
                    NavigationLink(destination: ParentChildAnalyticsView(
                        child: firstChild,
                        classroom: childrenClassrooms[firstChild.userId]?.first
                    )) {
                        QuickActionCard(
                            title: "Progress",
                            icon: "chart.line.uptrend.xyaxis",
                            color: .green,
                            description: "View analytics"
                        )
                    }
                } else {
                    QuickActionCard(
                        title: "Progress",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .green,
                        description: "View analytics"
                    )
                    .opacity(0.5)
                }
            }
            
            // Second row of actions - NEW PRACTICE HUB
            HStack(spacing: 12) {
                // Practice Hub - NEW
                if !children.isEmpty {
                    NavigationLink(destination: PracticeHubView(children: children)) {
                        QuickActionCard(
                            title: "Practice",
                            icon: "sparkles",
                            color: .purple,
                            description: "Generate problems"
                        )
                    }
                } else {
                    QuickActionCard(
                        title: "Practice",
                        icon: "sparkles",
                        color: .purple,
                        description: "Generate problems"
                    )
                    .opacity(0.5)
                }
                
                // Placeholder for future feature or leave empty
                Color.clear
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Learning Alerts Section
    private var learningAlertsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .foregroundColor(.orange)
                Text("Needs Attention")
                    .font(.title3.bold())
                
                Spacer()
                
                if children.count > 1 {
                    NavigationLink(destination: ParentAnalyticsOverviewView()) {
                        Text("View All")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            ForEach(childrenNeedingAttention, id: \.userId) { child in
                if let summary = childrenProgress[child.userId] {
                    NavigationLink(destination: ParentChildAnalyticsView(
                        child: child,
                        classroom: childrenClassrooms[child.userId]?.first
                    )) {
                        LearningAlertCard(child: child, summary: summary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var childrenNeedingAttention: [UserProfile] {
        children.filter { child in
            guard let summary = childrenProgress[child.userId] else { return false }
            return summary.overallProgress < 60 || summary.needsWorkCount > 2
        }
    }
    
    // MARK: - Children Section
    private var childrenSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Linked Children")
                .font(.title3.bold())
            
            ForEach(children, id: \.id) { child in
                NavigationLink {
                    EnhancedChildProgressView(
                        child: child,
                        classrooms: childrenClassrooms[child.userId] ?? [],
                        progressSummary: childrenProgress[child.userId]
                    )
                } label: {
                    EnhancedChildCard(
                        child: child,
                        classrooms: childrenClassrooms[child.userId] ?? [],
                        progressSummary: childrenProgress[child.userId]
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Profile Button
    private var profileButton: some View {
        NavigationLink {
            ProfileView()
        } label: {
            if let profile = awsService.currentUserProfile {
                Circle()
                    .fill(Color.blue.gradient)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(profile.initials)
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    )
            }
        }
    }
    
    // MARK: - Load Children
    private func loadChildren() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let linkedChildren = try await awsService.fetchLinkedChildren()
            
            // Load classrooms and progress for each child
            var classroomsByChild: [String: [Classroom]] = [:]
            var progressByChild: [String: ChildProgressSummary] = [:]
            
            for child in linkedChildren {
                // Fetch classrooms
                let memberships = try await Amplify.DataStore.query(
                    ClassroomMembership.self,
                    where: ClassroomMembership.keys.studentId == child.userId
                        && ClassroomMembership.keys.status == MembershipStatus.approved.rawValue
                )
                classroomsByChild[child.userId] = memberships.compactMap { $0.classroom }
                
                // Calculate progress summary
                let summary = try await calculateProgressSummary(for: child.userId)
                progressByChild[child.userId] = summary
            }
            
            await MainActor.run {
                self.children = linkedChildren
                self.childrenClassrooms = classroomsByChild
                self.childrenProgress = progressByChild
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func calculateProgressSummary(for studentId: String) async throws -> ChildProgressSummary {
        // Get concept mastery data
        let allMastery = try await Amplify.DataStore.query(ConceptMastery.self)
        let studentMastery = allMastery.filter { $0.studentId == studentId }
        
        // Calculate overall progress
        let overallProgress = studentMastery.isEmpty ? 0 :
            studentMastery.reduce(0.0) { $0 + $1.masteryPercentage } / Double(studentMastery.count)
        
        // Count mastered and needs work
        let masteredCount = studentMastery.filter { $0.masteryPercentage >= 80 }.count
        let needsWorkCount = studentMastery.filter { $0.masteryPercentage < 60 }.count
        
        // Get student progress for homework stats
        let allProgress = try await Amplify.DataStore.query(StudentProgress.self)
        let studentProgress = allProgress.first { $0.studentId == studentId }
        
        return ChildProgressSummary(
            overallProgress: overallProgress,
            masteredCount: masteredCount,
            needsWorkCount: needsWorkCount,
            homeworkCompleted: studentProgress?.totalHomeworkCompleted ?? 0,
            homeworkAssigned: studentProgress?.totalHomeworkAssigned ?? 0,
            currentStreak: studentProgress?.currentStreak ?? 0
        )
    }
}

// MARK: - Child Progress Summary

struct ChildProgressSummary {
    let overallProgress: Double
    let masteredCount: Int
    let needsWorkCount: Int
    let homeworkCompleted: Int
    let homeworkAssigned: Int
    let currentStreak: Int
    
    var completionRate: Double {
        homeworkAssigned > 0 ? Double(homeworkCompleted) / Double(homeworkAssigned) * 100 : 0
    }
}

// MARK: - Enhanced Child Card

struct EnhancedChildCard: View {
    let child: UserProfile
    let classrooms: [Classroom]
    let progressSummary: ChildProgressSummary?
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Avatar with progress ring
                ZStack {
                    // Progress ring
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                        .frame(width: 64, height: 64)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat((progressSummary?.overallProgress ?? 0) / 100))
                        .stroke(progressColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))
                    
                    // Avatar
                    Circle()
                        .fill(LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Text(child.initials)
                                .font(.headline.bold())
                                .foregroundColor(.white)
                        )
                }
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(child.displayName)
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        if let gradeLevel = child.gradeLevel {
                            Label(gradeLevel, systemImage: "graduationcap")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if !classrooms.isEmpty {
                            Label("\(classrooms.count) class\(classrooms.count == 1 ? "" : "es")", systemImage: "book.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Progress indicator
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(progressSummary?.overallProgress ?? 0))%")
                        .font(.title3.bold())
                        .foregroundColor(progressColor)
                    
                    statusBadge
                }
            }
            
            // Quick stats row
            if let summary = progressSummary {
                HStack(spacing: 16) {
                    MiniStatView(
                        icon: "checkmark.seal.fill",
                        value: "\(summary.masteredCount)",
                        label: "Mastered",
                        color: .green
                    )
                    
                    MiniStatView(
                        icon: "doc.text.fill",
                        value: "\(summary.homeworkCompleted)/\(summary.homeworkAssigned)",
                        label: "Homework",
                        color: .blue
                    )
                    
                    MiniStatView(
                        icon: "flame.fill",
                        value: "\(summary.currentStreak)",
                        label: "Streak",
                        color: .orange
                    )
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    private var progressColor: Color {
        let progress = progressSummary?.overallProgress ?? 0
        if progress >= 70 { return .green }
        if progress >= 50 { return .orange }
        return .red
    }
    
    private var statusBadge: some View {
        let progress = progressSummary?.overallProgress ?? 0
        let (text, color): (String, Color) = {
            if progress >= 80 { return ("Excellent", .green) }
            if progress >= 70 { return ("On Track", .green) }
            if progress >= 50 { return ("Progressing", .orange) }
            return ("Needs Help", .red)
        }()
        
        return Text(text)
            .font(.caption2.bold())
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.1))
            .cornerRadius(6)
    }
}

// MARK: - Mini Stat View

struct MiniStatView: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(color)
                Text(value)
                    .font(.caption.bold())
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Learning Alert Card

struct LearningAlertCard: View {
    let child: UserProfile
    let summary: ChildProgressSummary
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(child.displayName)
                    .font(.subheadline.bold())
                
                Text(alertMessage)
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
    
    private var alertMessage: String {
        if summary.overallProgress < 50 {
            return "Needs focused attention on \(summary.needsWorkCount) topics"
        } else if summary.needsWorkCount > 2 {
            return "\(summary.needsWorkCount) areas need extra practice"
        } else {
            return "Making progress but could use some help"
        }
    }
}

// MARK: - Enhanced Child Progress View

struct EnhancedChildProgressView: View {
    let child: UserProfile
    let classrooms: [Classroom]
    let progressSummary: ChildProgressSummary?
    
    @State private var selectedClassroom: Classroom?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Child Header
                //childHeaderSection
                
                // Quick Stats
                //quickStatsSection
                
                // Class Selection (if multiple)
                /*if classrooms.count > 1 {
                    classSelectionSection
                }*/
                
                // Analytics Link
                //analyticsSection
                
                // Classes Section
                classesSection
            }
            .padding()
        }
        .navigationTitle("\(child.displayName)'s Progress")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedClassroom = classrooms.first
        }
    }
    
    // MARK: - Child Header Section
    
    private var childHeaderSection: some View {
        VStack(spacing: 12) {
            // Avatar with progress ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: CGFloat((progressSummary?.overallProgress ?? 0) / 100))
                    .stroke(
                        LinearGradient(
                            colors: progressColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(child.initials)
                            .font(.title.bold())
                            .foregroundColor(.white)
                    )
            }
            
            Text(child.displayName)
                .font(.title2.bold())
            
            if let gradeLevel = child.gradeLevel {
                Text(gradeLevel)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Overall Progress
            HStack(spacing: 8) {
                Text("\(Int(progressSummary?.overallProgress ?? 0))%")
                    .font(.title.bold())
                    .foregroundColor(overallProgressColor)
                
                Text("Overall Progress")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var progressColors: [Color] {
        let progress = progressSummary?.overallProgress ?? 0
        if progress >= 70 { return [.green, .green.opacity(0.7)] }
        if progress >= 50 { return [.orange, .yellow] }
        return [.red, .orange]
    }
    
    private var overallProgressColor: Color {
        let progress = progressSummary?.overallProgress ?? 0
        if progress >= 70 { return .green }
        if progress >= 50 { return .orange }
        return .red
    }
    
    // MARK: - Quick Stats Section
    
    private var quickStatsSection: some View {
        HStack(spacing: 12) {
            PStatCard(
                title: "Mastered",
                value: "\(progressSummary?.masteredCount ?? 0)",
                icon: "checkmark.seal.fill",
                color: .green
            )
            
            PStatCard(
                title: "Homework",
                value: "\(progressSummary?.homeworkCompleted ?? 0)/\(progressSummary?.homeworkAssigned ?? 0)",
                icon: "doc.text.fill",
                color: .blue
            )
            
            PStatCard(
                title: "Streak",
                value: "\(progressSummary?.currentStreak ?? 0)",
                icon: "flame.fill",
                color: .orange
            )
        }
    }
    
    // MARK: - Class Selection Section
    
    private var classSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Class")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(classrooms, id: \.id) { classroom in
                        Button(action: { selectedClassroom = classroom }) {
                            Text(classroom.className)
                                .font(.subheadline)
                                .foregroundColor(selectedClassroom?.id == classroom.id ? .white : .primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(selectedClassroom?.id == classroom.id ? Color.purple : Color(.secondarySystemBackground))
                                )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Analytics Section
    
    private var analyticsSection: some View {
        NavigationLink(destination: ParentChildAnalyticsView(
            child: child,
            classroom: selectedClassroom ?? classrooms.first
        )) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("View Detailed Analytics")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Strengths, areas to improve, and how to help")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "chart.bar.fill")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.8))
            }
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
    
    // MARK: - Classes Section
    
    private var classesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Enrolled Classes")
                .font(.title3.bold())
            
            if classrooms.isEmpty {
                ContentUnavailableView(
                    "No classes yet",
                    systemImage: "book.closed",
                    description: Text("Your child hasn't joined any classes")
                )
                .frame(height: 200)
            } else {
                ForEach(classrooms, id: \.id) { classroom in
                    NavigationLink(destination: ParentChildAnalyticsView(
                        child: child,
                        classroom: classroom
                    )) {
                        ParentClassCard(classroom: classroom)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Stat Card

struct PStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2.bold())
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Parent Class Card

struct ParentClassCard: View {
    let classroom: Classroom
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "book.fill")
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(classroom.className)
                    .font(.headline)
                
                if let description = classroom.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 4, y: 2)
    }
}

// MARK: - Quick Action Card

private struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let description: String
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Student Class Card (kept for compatibility)

struct StudentClassCard: View {
    let classroom: Classroom
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "book.fill")
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(classroom.className)
                    .font(.headline)
                
                if let description = classroom.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 4, y: 2)
    }
}
