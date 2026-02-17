//
//  ParentHomeworkView.swift
//  PeaTutorApp
//
//  Sprint 6: Parent Dashboard - Homework monitoring for parents
//

import SwiftUI
import Amplify

struct ParentHomeworkView: View {
    @StateObject private var awsService = AWSService.shared
    @StateObject private var homeworkService = HomeworkService.shared
    
    @State private var children: [UserProfile] = []
    @State private var childrenHomework: [String: [Homework]] = [:] // childId: [Homework]
    @State private var childrenSubmissions: [String: [String: [FullWorksheetSolution]]] = [:] // childId: [homeworkId: [submissions]]
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedChild: UserProfile?
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading && children.isEmpty {
                    ProgressView("Loading children...")
                } else if children.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Overview Header
                            overviewSection
                            
                            // Children List with Homework Summary
                            childrenSection
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Homework Monitoring")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { 
                        Task { await loadData() }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
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
            
            Text("Link to your child's account to monitor their homework and progress")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("Go to the main dashboard to link a child account")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding(40)
    }
    
    // MARK: - Overview Section
    
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.title3.bold())
            
            HStack(spacing: 12) {
                OverviewStatCard(
                    title: "Children",
                    value: "\(children.count)",
                    icon: "person.2.fill",
                    color: .blue
                )
                
                OverviewStatCard(
                    title: "Total Homework",
                    value: "\(totalHomeworkCount)",
                    icon: "doc.text.fill",
                    color: .orange
                )
                
                OverviewStatCard(
                    title: "Pending",
                    value: "\(pendingHomeworkCount)",
                    icon: "clock.fill",
                    color: .red
                )
            }
        }
    }
    
    // MARK: - Children Section
    
    private var childrenSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("My Children")
                .font(.title3.bold())
            
            ForEach(children, id: \.userId) { child in
                NavigationLink(destination: ChildHomeworkListView(child: child)) {
                    ChildHomeworkSummaryCard(
                        child: child,
                        homework: childrenHomework[child.userId] ?? [],
                        submissions: childrenSubmissions[child.userId] ?? [:]
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var totalHomeworkCount: Int {
        childrenHomework.values.flatMap { $0 }.count
    }
    
    private var pendingHomeworkCount: Int {
        var count = 0
        for (childId, homework) in childrenHomework {
            let submissions = childrenSubmissions[childId] ?? [:]
            for hw in homework {
                let hwSubmissions = submissions[hw.id] ?? []
                if hwSubmissions.isEmpty {
                    count += 1
                }
            }
        }
        return count
    }
    
    // MARK: - Data Loading
    
    private func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 1. Fetch linked children
            guard let parentId = awsService.currentUserId else {
                throw NSError(domain: "ParentHomeworkView", code: -1, 
                            userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
            }
            
            let relationships = try await Amplify.DataStore.query(
                ParentChildRelationship.self,
                where: ParentChildRelationship.keys.parentId == parentId
                    && ParentChildRelationship.keys.status == LinkStatus.approved.rawValue
            )
            
            var fetchedChildren: [UserProfile] = []
            var homeworkMap: [String: [Homework]] = [:]
            var submissionsMap: [String: [String: [FullWorksheetSolution]]] = [:]
            
            // 2. For each child, fetch their profile, homework, and submissions
            for relationship in relationships {
                // Fetch child profile
                let profiles = try await Amplify.DataStore.query(
                    UserProfile.self,
                    where: UserProfile.keys.userId == relationship.childId
                )
                
                guard let childProfile = profiles.first else { continue }
                fetchedChildren.append(childProfile)
                
                // Fetch child's homework
                let homework = try await homeworkService.fetchStudentHomework(studentId: childProfile.userId)
                homeworkMap[childProfile.userId] = homework
                
                // Fetch submissions for each homework
                var childSubmissions: [String: [FullWorksheetSolution]] = [:]
                for hw in homework {
                    let submissions = try await homeworkService.fetchStudentSubmissions(
                        homeworkId: hw.id,
                        studentId: childProfile.userId
                    )
                    childSubmissions[hw.id] = submissions
                }
                submissionsMap[childProfile.userId] = childSubmissions
            }
            
            await MainActor.run {
                self.children = fetchedChildren.sorted { $0.displayName < $1.displayName }
                self.childrenHomework = homeworkMap
                self.childrenSubmissions = submissionsMap
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Child Homework Summary Card

struct ChildHomeworkSummaryCard: View {
    let child: UserProfile
    let homework: [Homework]
    let submissions: [String: [FullWorksheetSolution]] // homeworkId: [submissions]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 16) {
                // Avatar
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(child.initials)
                            .font(.title2.bold())
                            .foregroundColor(.blue)
                    )
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(child.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let grade = child.gradeLevel {
                        Text("Grade \(grade)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let school = child.schoolName {
                        Text(school)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            Divider()
            
            // Stats
            HStack(spacing: 0) {
                StatItem(
                    label: "Total",
                    value: "\(homework.count)",
                    color: .blue
                )
                
                Divider()
                    .frame(height: 40)
                
                StatItem(
                    label: "Submitted",
                    value: "\(submittedCount)",
                    color: .green
                )
                
                Divider()
                    .frame(height: 40)
                
                StatItem(
                    label: "Pending",
                    value: "\(pendingCount)",
                    color: .orange
                )
                
                Divider()
                    .frame(height: 40)
                
                StatItem(
                    label: "Overdue",
                    value: "\(overdueCount)",
                    color: .red
                )
            }
            .frame(height: 70)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
    
    private var submittedCount: Int {
        homework.filter { hw in
            !(submissions[hw.id] ?? []).isEmpty
        }.count
    }
    
    private var pendingCount: Int {
        homework.filter { hw in
            let hwSubmissions = submissions[hw.id] ?? []
            return hwSubmissions.isEmpty && !isOverdue(hw)
        }.count
    }
    
    private var overdueCount: Int {
        homework.filter { hw in
            let hwSubmissions = submissions[hw.id] ?? []
            return hwSubmissions.isEmpty && isOverdue(hw)
        }.count
    }
    
    private func isOverdue(_ homework: Homework) -> Bool {
        Date() > homework.dueDate.foundationDate
    }
}

// MARK: - Stat Item

private struct StatItem: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Overview Stat Card

struct OverviewStatCard: View {
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
                .font(.title.bold())
            
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
