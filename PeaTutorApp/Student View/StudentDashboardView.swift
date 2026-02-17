//
//  StudentDashboardView.swift
//  PeaTutorApp
//
//  Sprint 8: Refined Student Dashboard
//  Class-first architecture with simplified navigation
//

import SwiftUI
import Amplify

struct StudentDashboardView: View {
    @StateObject private var awsService = AWSService.shared
    @State private var classes: [Classroom] = []
    @State private var classStats: [String: ClassQuickStats] = [:]
    @State private var isLoading = false
    @State private var showJoinClass = false
    @State private var errorMessage: String?
    @State private var studentGradeLevel: String = "Primary 3"
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading classes...")
                } else if classes.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Welcome Header
                            welcomeHeader
                            
                            // Quick Stats Summary
                            //quickStatsBar
                            
                            // Classes List
                            classesSection
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showJoinClass = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    profileButton
                }
            }
            .sheet(isPresented: $showJoinClass) {
                JoinClassView(onClassJoined: loadClasses)
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .task {
                await loadClasses()
            }
            .refreshable {
                await loadClasses()
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text("No Classes Yet")
                    .font(.title2.bold())
                
                Text("Join a class using your teacher's class code to get started")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: { showJoinClass = true }) {
                Label("Join Class", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: 200)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
        }
        .padding(40)
    }
    
    // MARK: - Welcome Header
    
    private var welcomeHeader: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back,")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let profile = awsService.currentUserProfile {
                    Text(profile.displayName)
                        .font(.title2.bold())
                }
            }
            
            Spacer()
            
            // Today's date
            VStack(alignment: .trailing, spacing: 2) {
                Text(Date(), format: .dateTime.weekday(.wide))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(Date(), format: .dateTime.month().day())
                    .font(.subheadline.bold())
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Quick Stats Bar
    
    private var quickStatsBar: some View {
        HStack(spacing: 12) {
            QuickStatCard2(
                icon: "clock.fill",
                value: "\(totalPendingHomework)",
                label: "Due Soon",
                color: totalPendingHomework > 0 ? .orange : .green
            )
            
            QuickStatCard2(
                icon: "checkmark.circle.fill",
                value: "\(totalCompletedHomework)",
                label: "Completed",
                color: .green
            )
            
            QuickStatCard2(
                icon: "sparkles",
                value: "\(totalPracticeAvailable)",
                label: "Practice",
                color: .purple
            )
        }
    }
    
    // MARK: - Classes Section
    
    private var classesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("My Classes")
                    .font(.title3.bold())
                
                Spacer()
                
                Text("\(classes.count) class\(classes.count == 1 ? "" : "es")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                ForEach(classes, id: \.id) { classroom in
                    NavigationLink {
                        StudentClassDetailView(classroom: classroom)
                    } label: {
                        ClassCardWithStats(
                            classroom: classroom,
                            stats: classStats[classroom.id]
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
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
                    .fill(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(profile.initials)
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    )
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var totalPendingHomework: Int {
        classStats.values.reduce(0) { $0 + $1.pendingHomework }
    }
    
    private var totalCompletedHomework: Int {
        classStats.values.reduce(0) { $0 + $1.completedHomework }
    }
    
    private var totalPracticeAvailable: Int {
        classStats.values.reduce(0) { $0 + $1.practiceAvailable }
    }
    
    // MARK: - Load Classes
    
    private func loadClasses() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let fetchedClasses = try await awsService.fetchStudentClasses()
            
            // Sort by most recently joined/created
            let sortedClasses = fetchedClasses.sorted { c1, c2 in
                guard let date1 = c1.createdAt, let date2 = c2.createdAt else {
                    return false
                }
                return date1 > date2
            }
            
            // Load stats for each class
            var stats: [String: ClassQuickStats] = [:]
            for classroom in sortedClasses {
                stats[classroom.id] = await loadClassStats(for: classroom)
            }
            
            await MainActor.run {
                self.classes = sortedClasses
                self.classStats = stats
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func loadClassStats(for classroom: Classroom) async -> ClassQuickStats {
        guard let userId = awsService.currentUserId else {
            return ClassQuickStats()
        }
        
        do {
            // Fetch homework for this class
            let homework = try await HomeworkService.shared.fetchClassroomHomework(
                classroomId: classroom.id,
                publishedOnly: true
            )
            
            var pending = 0
            var completed = 0
            
            for hw in homework {
                // Check if user has submitted
                let submissions = try await Amplify.DataStore.query(
                    FullWorksheetSolution.self,
                    where: FullWorksheetSolution.keys.homework.eq(hw.id)
                        && FullWorksheetSolution.keys.userId == userId
                )
                
                if submissions.isEmpty {
                    pending += 1
                } else {
                    completed += 1
                }
            }
            
            // Count concepts for practice (simplified - just count available)
            let concepts = try await Amplify.DataStore.query(
                ConceptMastery.self,
                where: ConceptMastery.keys.studentId == userId
                    && ConceptMastery.keys.classroomId == classroom.id
            )
            
            // Practice available = concepts needing work (mastery < 80%)
            let practiceAvailable = concepts.filter { $0.masteryPercentage < 80 }.count
            
            return ClassQuickStats(
                pendingHomework: pending,
                completedHomework: completed,
                practiceAvailable: max(practiceAvailable, pending > 0 ? 1 : 0) // At least 1 if homework pending
            )
            
        } catch {
            print("⚠️ Failed to load stats for \(classroom.className): \(error)")
            return ClassQuickStats()
        }
    }
}

// MARK: - Class Quick Stats Model

struct ClassQuickStats {
    var pendingHomework: Int = 0
    var completedHomework: Int = 0
    var practiceAvailable: Int = 0
    var worksheetCount: Int = 0
}

// MARK: - Quick Stat Card

private struct QuickStatCard2: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(value)
                    .font(.title2.bold())
            }
            .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Class Card With Stats

private struct ClassCardWithStats: View {
    let classroom: Classroom
    let stats: ClassQuickStats?
    
    // Color based on classroom position (cycles through)
    private var classColor: Color {
        let colors: [Color] = [.blue, .green, .purple, .orange, .pink]
        let hash = classroom.id.hashValue
        return colors[abs(hash) % colors.count]
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Class Icon
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(classColor.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "book.fill")
                    .font(.title2)
                    .foregroundColor(classColor)
            }
            
            // Class Info
            VStack(alignment: .leading, spacing: 6) {
                Text(classroom.className)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let subject = classroom.subject {
                    Text(subject)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Status Badge
                if let stats = stats {
                    HStack(spacing: 8) {
                        if stats.pendingHomework > 0 {
                            StatusBadge2(
                                text: "\(stats.pendingHomework) due",
                                icon: "clock.fill",
                                color: .orange
                            )
                        } else {
                            StatusBadge2(
                                text: "All done",
                                icon: "checkmark.circle.fill",
                                color: .green
                            )
                        }
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Status Badge

struct StatusBadge2: View {
    let text: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .cornerRadius(6)
    }
}
