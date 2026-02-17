//
//  DashboardCurriculumIntegration.swift
//  PeaTutorApp
//
//  Sprint 8 Phase 5: Dashboard Integration Guide
//  Shows how to add curriculum widgets to existing dashboards
//

import SwiftUI
import Amplify

// MARK: - Class Curriculum Detail View (Full View for Teachers)

struct ClassCurriculumDetailView: View {
    let classroom: Classroom
    
    @State private var studentProgresses: [StudentCurriculumProgress] = []
    @State private var studentProfiles: [String: UserProfile] = [:]
    @State private var isLoading = false
    @State private var selectedStudent: StudentCurriculumProgress?
    
    private var gradeLevelCode: String {
        CurriculumService.gradeLevelToCode(classroom.gradeLevel ?? "Primary 3") ?? "P3"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Class Overview Card
                ClassCurriculumOverviewCard(
                    classroomId: classroom.id,
                    gradeLevel: classroom.gradeLevel ?? "Primary 3"
                )
                
                // Student List
                studentProgressList
            }
            .padding()
        }
        .navigationTitle("Class Curriculum")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadData()
        }
    }
    
    private var studentProgressList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Individual Progress")
                .font(.title3.bold())
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if studentProgresses.isEmpty {
                Text("No curriculum data available yet.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                // Sort by mastery (lowest first for attention)
                ForEach(studentProgresses.sorted { $0.masteryPercentage < $1.masteryPercentage }, id: \.id) { progress in
                    NavigationLink {
                        if let profile = studentProfiles[progress.studentId] {
                            StudentCurriculumProgressView(
                                studentId: progress.studentId,
                                studentName: profile.displayName,
                                classroomId: classroom.id,
                                gradeLevel: classroom.gradeLevel ?? "Primary 3"
                            )
                        }
                    } label: {
                        TeacherStudentProgressRow(
                            progress: progress,
                            studentName: studentProfiles[progress.studentId]?.displayName ?? "Student"
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load student progresses for this class
            let allProgress = try await Amplify.DataStore.query(StudentCurriculumProgress.self)
            studentProgresses = allProgress.filter {
                $0.classroomId == classroom.id &&
                $0.gradeLevelCode == gradeLevelCode
            }
            
            // Load profiles for students
            let studentIds = Set(studentProgresses.map { $0.studentId })
            let allProfiles = try await Amplify.DataStore.query(UserProfile.self)
            for profile in allProfiles where studentIds.contains(profile.userId) {
                studentProfiles[profile.userId] = profile
            }
        } catch {
            print("⚠️ Failed to load class curriculum data: \(error)")
        }
    }
}

// MARK: - Teacher Student Progress Row

struct TeacherStudentProgressRow: View {
    let progress: StudentCurriculumProgress
    let studentName: String
    
    private var statusColor: Color {
        if progress.masteryPercentage >= 70 { return .green }
        if progress.masteryPercentage >= 50 { return .orange }
        return .red
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Student avatar
            Circle()
                .fill(statusColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(studentName.prefix(2)).uppercased())
                        .font(.caption.bold())
                        .foregroundColor(statusColor)
                )
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(studentName)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Label("\(progress.topicsMastered) mastered", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    if let gaps = progress.prerequisiteGaps, !gaps.compactMap({ $0 }).isEmpty {
                        Label("\(gaps.compactMap { $0 }.count) gaps", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            // Progress indicator
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(progress.masteryPercentage))%")
                    .font(.headline)
                    .foregroundColor(statusColor)
                Text("mastery")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 4, y: 2)
    }
}

// MARK: - Quick Integration Checklist
/*
 ============================================================================
 INTEGRATION CHECKLIST
 ============================================================================
 
 □ 1. Add files to project:
   - StudentCurriculumProgressView.swift
   - CurriculumProgressWidgets.swift
   - DashboardCurriculumIntegration.swift (optional, for reference)
 
 □ 2. Update StudentDashboardView:
   - Add curriculumProgressSection after quickStatsBar
   - Add NavigationLink to full progress view
 
 □ 3. Update ParentChildAnalyticsView:
   - Add "Curriculum" tab to ParentAnalyticsTab enum
   - Add curriculumTab view
   - Add parent-friendly tips
 
 □ 4. Update ClassAnalyticsDashboardView:
   - Add ClassCurriculumOverviewCard
   - Add NavigationLink to ClassCurriculumDetailView
 
 □ 5. Update StudentClassDetailView:
   - Add curriculum progress link/button
 
 □ 6. Ensure models are up to date:
   - StudentCurriculumProgress model exists
   - CurriculumStandard model has required fields
   - ConceptMastery has curriculum fields
 
 □ 7. Test:
   - Seed curriculum data using CurriculumService.seedFromBundledJSON()
   - Submit some homework to generate mastery data
   - Check progress views populate correctly
 
 ============================================================================
 */
