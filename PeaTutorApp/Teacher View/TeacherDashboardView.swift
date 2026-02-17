//
//  TeacherDashboardView.swift
//  PeaTutorApp
//
//  Created by Charles on 19/10/25.
//

import SwiftUI
import Amplify

struct TeacherDashboardView: View {
    @StateObject private var awsService = AWSService.shared
    @State private var classes: [Classroom] = []
    @State private var isLoading = false
    @State private var showCreateClass = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView("Loading classes...")
                } else if classes.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            
                            // Header Stats
                            statsSection
                            
                            // Classes Grid
                            classesSection
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Classes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showCreateClass = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    profileButton
                }
            }
            .sheet(isPresented: $showCreateClass) {
                CreateClassView(onClassCreated: loadClasses)
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
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)
            
            Text("No Classes Yet")
                .font(.title2.bold())
            
            Text("Create your first class to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showCreateClass = true }) {
                Label("Create Class", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: 200)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .padding(40)
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 16) {
            TStatCard(
                title: "Classes",
                value: "\(classes.count)",
                icon: "book.fill",
                color: .blue
            )
            
            TStatCard(
                title: "Students",
                value: "\(totalStudents)",
                icon: "person.2.fill",
                color: .green
            )
            
            TStatCard(
                title: "Active",
                value: "\(activeClasses)",
                icon: "checkmark.circle.fill",
                color: .orange
            )
        }
    }
    
    // MARK: - Classes Section
    private var classesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Classes")
                .font(.title2.bold())
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(classes, id: \.id) { classroom in
                    NavigationLink {
                        ClassDetailView(classroom: classroom)
                    } label: {
                        ClassCard(classroom: classroom)
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
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.blue.gradient)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(profile.initials)
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.displayName)
                            .font(.caption.bold())
                        Text(profile.userRole.displayName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var totalStudents: Int {
        memberCounts.values.reduce(0, +)
    }

    private var activeClasses: Int {
        classes.filter { $0.isActive }.count
    }

    // Add state for member counts
    @State private var memberCounts: [String: Int] = [:] // classroomId -> count

    // MARK: - Load Classes
    private func loadClasses() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let fetchedClasses = try await awsService.fetchTeacherClasses()
            await MainActor.run {
                self.classes = fetchedClasses.sorted(by: {
                            guard let date1 = $0.createdAt, let date2 = $1.createdAt else {
                                return false
                            }
                            return date1 > date2
                        })
            }
            
            // Load member counts for all classes
            await loadMemberCounts()
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadMemberCounts() async {
        var counts: [String: Int] = [:]
        
        for classroom in classes {
            do {
                let memberships = try await Amplify.DataStore.query(
                    ClassroomMembership.self,
                    where: ClassroomMembership.keys.classroom.eq(classroom.id)
                        && ClassroomMembership.keys.status == MembershipStatus.approved.rawValue
                )
                counts[classroom.id] = memberships.count
            } catch {
                print("❌ Failed to load count for \(classroom.className): \(error)")
                counts[classroom.id] = 0
            }
        }
        
        await MainActor.run {
            self.memberCounts = counts
        }
    }
    

}

// MARK: - Stat Card
private struct TStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title.bold())
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Class Card
struct ClassCard: View {
    let classroom: Classroom
    @State private var memberCount: Int = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon & Status
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "book.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                if classroom.isActive {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                }
            }
            
            // Class Info
            VStack(alignment: .leading, spacing: 4) {
                Text(classroom.className)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                if let subject = classroom.subject {
                    Text(subject)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Footer
            HStack {
                Label("\(memberCount)", systemImage: "person.2")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(classroom.classCode)
                    .font(.caption.bold())
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding()
        .frame(height: 180)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        .task {
            await loadMemberCount()
        }
    }
    
    // ✅ Load member count from DataStore
    private func loadMemberCount() async {
        do {
            let memberships = try await Amplify.DataStore.query(
                ClassroomMembership.self,
                where: ClassroomMembership.keys.classroom.eq(classroom.id)
                    && ClassroomMembership.keys.status == MembershipStatus.approved.rawValue
            )
            memberCount = memberships.count
        } catch {
            print("❌ Failed to load member count: \(error)")
            memberCount = 0
        }
    }
}
