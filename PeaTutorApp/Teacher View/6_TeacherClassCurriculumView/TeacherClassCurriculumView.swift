//
//  TeacherClassCurriculumView.swift
//  PeaTutorApp
//
//  Created by Charles on 6/12/25.
//

import SwiftUI
import Amplify

extension UserProfile: Identifiable {}

struct TeacherClassCurriculumView: View {
    let classroom: Classroom
    
    @State private var students: [UserProfile] = []
    @State private var isLoading = false
    @State private var selectedStudent: UserProfile?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Class header
                classHeaderCard
                
                // Student list with curriculum progress
                if isLoading {
                    ProgressView("Loading students...")
                        .padding(40)
                } else if students.isEmpty {
                    emptyStateView
                } else {
                    studentListSection
                }
            }
            .padding()
        }
        .navigationTitle("Class Curriculum")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadStudents()
        }
        .sheet(item: $selectedStudent) { student in
            NavigationStack {
                CurriculumStrandProgressView(
                    studentId: student.userId,
                    classroomId: classroom.id,
                    gradeLevel: classroom.gradeLevel ?? "Primary 1",
                    studentName: student.displayName,
                    showHeader: true,
                    accentColor: .blue
                )
                .navigationTitle("\(student.displayName)'s Progress")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { selectedStudent = nil }
                    }
                }
            }
        }
    }
    
    // MARK: - Class Header
    private var classHeaderCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "graduationcap.fill")
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(classroom.className)
                    .font(.headline)
                Text(classroom.gradeLevel ?? "Primary 1")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(students.count) students")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Student List
    private var studentListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Students")
                .font(.headline)
            
            ForEach(students, id: \.userId) { student in
                StudentCurriculumCard(
                    student: student,
                    classroomId: classroom.id,
                    gradeLevel: classroom.gradeLevel ?? "Primary 1"
                ) {
                    selectedStudent = student
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No Students")
                .font(.headline)
            
            Text("Students will appear here once they join the class.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Load Students
    private func loadStudents() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let memberships = try await Amplify.DataStore.query(
                ClassroomMembership.self,
                where: ClassroomMembership.keys.classroom.eq(classroom.id)
            )
            
            let studentIds = memberships.map { $0.studentId }
            let profiles = try await Amplify.DataStore.query(UserProfile.self)
            students = profiles.filter { studentIds.contains($0.userId) }
                .sorted { $0.displayName < $1.displayName }
        } catch {
            print("⚠️ Failed to load students: \(error)")
        }
    }
}

// MARK: - Student Curriculum Card (for list view)

struct StudentCurriculumCard: View {
    let student: UserProfile
    let classroomId: String
    let gradeLevel: String
    let onTap: () -> Void
    
    @State private var progress: StudentCurriculumProgress?
    
    private var gradeLevelCode: String {
        CurriculumService.gradeLevelToCode(gradeLevel) ?? "P1"
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Student avatar
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(student.initials)
                            .font(.headline)
                            .foregroundColor(.blue)
                    )
                
                // Name and progress summary
                VStack(alignment: .leading, spacing: 4) {
                    Text(student.displayName)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    
                    if let progress = progress {
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "chart.pie.fill")
                                    .font(.caption2)
                                Text("\(Int(progress.coveragePercentage))%")
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                Text("\(Int(progress.masteryPercentage))%")
                                    .font(.caption)
                            }
                            .foregroundColor(progress.masteryPercentage >= 70 ? .green : .orange)
                            
                            Text("• \(progress.topicsMastered)/\(progress.totalTopicsInGrade) topics")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("No curriculum data yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .task {
            await loadProgress()
        }
    }
    
    private func loadProgress() async {
        do {
            let allProgress = try await Amplify.DataStore.query(StudentCurriculumProgress.self)
            progress = allProgress.first {
                $0.studentId == student.userId &&
                $0.classroomId == classroomId &&
                $0.gradeLevelCode == gradeLevelCode
            }
        } catch {
            print("Failed to load progress: \(error)")
        }
    }
}
