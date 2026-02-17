//
//  PracticeAssignmentService.swift
//  PeaTutorApp
//
//  Service for managing practice assignments
//  Mirrors HomeworkService patterns for consistency
//

import Foundation
import Amplify

/// Service for managing practice assignments
/// Handles creation, fetching, and updating of practice assignments
@MainActor
class PracticeAssignmentService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Singleton
    static let shared = PracticeAssignmentService()
    private init() {}
    
    // MARK: - Create Assignment
    
    /// Create a new practice assignment
    /// - Parameters:
    ///   - assignedByUserId: User ID of the person creating the assignment
    ///   - assignedByRole: Role of assigner (teacher, parent, student)
    ///   - studentId: Student who should complete the practice
    ///   - classroomId: Optional classroom context
    ///   - title: Assignment title
    ///   - description: Optional description/instructions
    ///   - dueDate: Optional due date
    ///   - problems: Array of generated practice problems
    ///   - sourceType: Source of the assignment (prerequisite_gap, recommended, etc.)
    ///   - curriculumCodes: Related curriculum codes
    ///   - curriculumGradeLevel: Grade level for curriculum
    ///   - targetConcepts: Concepts being practiced
    func createAssignment(
        assignedByUserId: String,
        assignedByRole: PracticeAssignment.AssignerRole,
        studentId: String,
        classroomId: String? = nil,
        title: String,
        description: String? = nil,
        dueDate: Date? = nil,
        problems: [PracticeProblem],
        sourceType: PracticeAssignment.SourceType,
        curriculumCodes: [String]? = nil,
        curriculumGradeLevel: String? = nil,
        targetConcepts: [String]? = nil
    ) async throws -> PracticeAssignment {
        
        guard !problems.isEmpty else {
            throw PracticeAssignmentError.noProblems
        }
        
        let problemIds = problems.map { $0.id }
        
        let assignment = PracticeAssignment(
            assignedByUserId: assignedByUserId,
            assignedByRole: assignedByRole.rawValue,
            studentId: studentId,
            classroomId: classroomId,
            title: title,
            description: description,
            dueDate: dueDate.map { Temporal.DateTime($0) },
            assignedDate: Temporal.DateTime(Date()),
            problemIds: problemIds,
            problemCount: problems.count,
            curriculumCodes: curriculumCodes?.map { Optional($0) },
            curriculumGradeLevel: curriculumGradeLevel,
            targetConcepts: targetConcepts?.map { Optional($0) },
            sourceType: sourceType.rawValue,
            status: PracticeAssignment.Status.pending.rawValue
        )
        
        let savedAssignment = try await Amplify.DataStore.save(assignment)
        
        print("âœ… Practice assignment created: \(savedAssignment.id)")
        print("   Title: \(savedAssignment.title)")
        print("   Student: \(savedAssignment.studentId)")
        print("   Problems: \(savedAssignment.problemCount)")
        print("   Source: \(savedAssignment.sourceType)")
        
        return savedAssignment
    }
    
    /// Create multiple assignments for a class (teacher assigning to all students)
    func createClassAssignments(
        teacherId: String,
        classroomId: String,
        title: String,
        description: String? = nil,
        dueDate: Date? = nil,
        problems: [PracticeProblem],
        sourceType: PracticeAssignment.SourceType,
        curriculumCodes: [String]? = nil,
        curriculumGradeLevel: String? = nil,
        targetConcepts: [String]? = nil
    ) async throws -> [PracticeAssignment] {
        
        // Get all approved students in the classroom
        let memberships = try await Amplify.DataStore.query(ClassroomMembership.self)
        let classroomStudents = memberships.filter { membership in
            membership.classroom?.id == classroomId &&
            membership.status == .approved
        }
        
        guard !classroomStudents.isEmpty else {
            throw PracticeAssignmentError.noStudentsInClass
        }
        
        var assignments: [PracticeAssignment] = []
        
        for membership in classroomStudents {
            let studentId = membership.studentId
            
            let assignment = try await createAssignment(
                assignedByUserId: teacherId,
                assignedByRole: .teacher,
                studentId: studentId,
                classroomId: classroomId,
                title: title,
                description: description,
                dueDate: dueDate,
                problems: problems,
                sourceType: sourceType,
                curriculumCodes: curriculumCodes,
                curriculumGradeLevel: curriculumGradeLevel,
                targetConcepts: targetConcepts
            )
            
            assignments.append(assignment)
        }
        
        print("âœ… Created \(assignments.count) practice assignments for classroom")
        return assignments
    }
    
    // MARK: - Fetch Assignments
    
    /// Fetch all assignments for a student
    func fetchStudentAssignments(studentId: String) async throws -> [PracticeAssignment] {
        let predicate = PracticeAssignment.keys.studentId == studentId
        let assignments = try await Amplify.DataStore.query(PracticeAssignment.self, where: predicate)
        
        // Sort by status (pending first) then by due date
        return assignments.sorted { a1, a2 in
            // Pending assignments first
            if a1.statusEnum != a2.statusEnum {
                let order: [PracticeAssignment.Status] = [.pending, .inProgress, .completed]
                let idx1 = order.firstIndex(of: a1.statusEnum) ?? 0
                let idx2 = order.firstIndex(of: a2.statusEnum) ?? 0
                return idx1 < idx2
            }
            
            // Then by due date (earliest first), nil due dates last
            if let d1 = a1.dueDate, let d2 = a2.dueDate {
                return d1.foundationDate < d2.foundationDate
            } else if a1.dueDate != nil {
                return true
            } else if a2.dueDate != nil {
                return false
            }
            
            // Then by assigned date (newest first)
            return a1.assignedDate.foundationDate > a2.assignedDate.foundationDate
        }
    }
    
    /// Fetch pending assignments for a student
    func fetchPendingAssignments(studentId: String) async throws -> [PracticeAssignment] {
        let assignments = try await fetchStudentAssignments(studentId: studentId)
        return assignments.filter { $0.statusEnum == .pending || $0.statusEnum == .inProgress }
    }
    
    /// Fetch completed assignments for a student
    func fetchCompletedAssignments(studentId: String) async throws -> [PracticeAssignment] {
        let assignments = try await fetchStudentAssignments(studentId: studentId)
        return assignments.filter { $0.statusEnum == .completed }
    }
    
    /// Fetch assignments created by a specific user (teacher/parent)
    func fetchAssignedByUser(userId: String) async throws -> [PracticeAssignment] {
        let predicate = PracticeAssignment.keys.assignedByUserId == userId
        let assignments = try await Amplify.DataStore.query(PracticeAssignment.self, where: predicate)
        
        return assignments.sorted { a1, a2 in
            a1.assignedDate.foundationDate > a2.assignedDate.foundationDate
        }
    }
    
    /// Fetch assignments for a classroom
    func fetchClassroomAssignments(classroomId: String) async throws -> [PracticeAssignment] {
        let predicate = PracticeAssignment.keys.classroomId == classroomId
        let assignments = try await Amplify.DataStore.query(PracticeAssignment.self, where: predicate)
        
        return assignments.sorted { a1, a2 in
            a1.assignedDate.foundationDate > a2.assignedDate.foundationDate
        }
    }
    
    /// Fetch a single assignment by ID
    func fetchAssignment(id: String) async throws -> PracticeAssignment? {
        return try await Amplify.DataStore.query(PracticeAssignment.self, byId: id)
    }
    
    /// Fetch assignments for a parent's child
    func fetchChildAssignments(childId: String, parentId: String) async throws -> [PracticeAssignment] {
        // Verify parent-child relationship
        let relationships = try await Amplify.DataStore.query(ParentChildRelationship.self)
        let isLinked = relationships.contains { rel in
            rel.parentId == parentId &&
            rel.childId == childId &&
            rel.status == .approved
        }
        
        guard isLinked else {
            throw PracticeAssignmentError.unauthorized
        }
        
        return try await fetchStudentAssignments(studentId: childId)
    }
    
    // MARK: - Update Assignment Status
    
    /// Mark assignment as started
    func startAssignment(_ assignment: PracticeAssignment) async throws -> PracticeAssignment {
        guard assignment.statusEnum == .pending else {
            // Already started or completed
            return assignment
        }
        
        var updated = assignment
        updated.status = PracticeAssignment.Status.inProgress.rawValue
        updated.startedAt = Temporal.DateTime(Date())
        
        let saved = try await Amplify.DataStore.save(updated)
        print("âœ… Assignment started: \(saved.id)")
        return saved
    }
    
    /// Mark assignment as completed with results
    func completeAssignment(
        _ assignment: PracticeAssignment,
        correctCount: Int,
        totalAttempted: Int,
        timeSpentSeconds: Int
    ) async throws -> PracticeAssignment {
        
        var updated = assignment
        updated.status = PracticeAssignment.Status.completed.rawValue
        updated.completedAt = Temporal.DateTime(Date())
        updated.correctCount = correctCount
        updated.totalAttempted = totalAttempted
        updated.timeSpentSeconds = timeSpentSeconds
        
        // Calculate score
        if totalAttempted > 0 {
            updated.score = (Double(correctCount) / Double(totalAttempted)) * 100.0
        } else {
            updated.score = 0
        }
        
        // Set startedAt if not already set
        if updated.startedAt == nil {
            updated.startedAt = updated.completedAt
        }
        
        let saved = try await Amplify.DataStore.save(updated)
        
        print("âœ… Assignment completed: \(saved.id)")
        print("   Score: \(saved.correctCount ?? 0)/\(saved.totalAttempted ?? 0) (\(saved.scorePercentageString))")
        print("   Time: \(saved.timeSpentFormatted)")
        
        return saved
    }
    
    /// Update assignment progress (partial completion)
    func updateProgress(
        _ assignment: PracticeAssignment,
        correctCount: Int,
        totalAttempted: Int,
        timeSpentSeconds: Int
    ) async throws -> PracticeAssignment {
        
        var updated = assignment
        
        // Mark as in progress if pending
        if updated.statusEnum == .pending {
            updated.status = PracticeAssignment.Status.inProgress.rawValue
            updated.startedAt = Temporal.DateTime(Date())
        }
        
        updated.correctCount = correctCount
        updated.totalAttempted = totalAttempted
        updated.timeSpentSeconds = timeSpentSeconds
        
        if totalAttempted > 0 {
            updated.score = (Double(correctCount) / Double(totalAttempted)) * 100.0
        }
        
        let saved = try await Amplify.DataStore.save(updated)
        print("âœ… Assignment progress updated: \(saved.id) - \(totalAttempted)/\(saved.problemCount) attempted")
        return saved
    }
    
    // MARK: - Delete Assignment
    
    /// Delete an assignment (only by the assigner)
    func deleteAssignment(_ assignment: PracticeAssignment, byUserId: String) async throws {
        guard assignment.assignedByUserId == byUserId else {
            throw PracticeAssignmentError.unauthorized
        }
        
        try await Amplify.DataStore.delete(assignment)
        print("âœ… Assignment deleted: \(assignment.id)")
    }
    
    // MARK: - Fetch Problems for Assignment
    
    /// Fetch the PracticeProblem records for an assignment
    /// Uses hybrid approach: try DataStore first, then API for missing problems
    func fetchProblemsForAssignment(_ assignment: PracticeAssignment) async throws -> [PracticeProblem] {
        var problems: [PracticeProblem] = []
        var missingIds: [String] = []
        
        print("📋 Fetching \(assignment.problemIds.count) problems for assignment: \(assignment.title)")
        
        // Step 1: Try to get from local DataStore first (fast, offline-capable)
        for problemId in assignment.problemIds {
            if let problem = try await Amplify.DataStore.query(PracticeProblem.self, byId: problemId) {
                problems.append(problem)
                print("   ✅ Found in DataStore: \(problemId)")
            } else {
                missingIds.append(problemId)
                print("   ⚠️ Not in DataStore: \(problemId)")
            }
        }
        
        // Step 2: If some problems are missing, try fetching from API directly
        if !missingIds.isEmpty {
            print("🌐 Fetching \(missingIds.count) missing problems from cloud API...")
            
            for problemId in missingIds {
                do {
                    // Query API directly for fresh data using list with predicate
                    let request = GraphQLRequest<PracticeProblem>.list(
                        PracticeProblem.self,
                        where: PracticeProblem.keys.id == problemId
                    )
                    let result = try await Amplify.API.query(request: request)
                    
                    switch result {
                    case .success(let fetchedProblems):
                        if let problem = fetchedProblems.first {
                            problems.append(problem)
                            print("   ✅ Fetched from API: \(problemId)")
                            
                            // Save to DataStore for future offline access
                            do {
                                try await Amplify.DataStore.save(problem)
                                print("   💾 Saved to DataStore for offline access")
                            } catch {
                                print("   ⚠️ Failed to cache locally: \(error)")
                            }
                        } else {
                            print("   ❌ Problem not found in cloud: \(problemId)")
                        }
                    case .failure(let error):
                        print("   ❌ API fetch failed for \(problemId): \(error)")
                    }
                } catch {
                    print("   ❌ Error fetching \(problemId): \(error)")
                }
            }
        }
        
        print("📋 Total problems fetched: \(problems.count)/\(assignment.problemIds.count)")
        return problems
    }
    
    // MARK: - Statistics
    
    /// Get assignment statistics for a student
    func getStudentStats(studentId: String) async throws -> PracticeAssignmentStats {
        let assignments = try await fetchStudentAssignments(studentId: studentId)
        
        let total = assignments.count
        let pending = assignments.filter { $0.statusEnum == .pending }.count
        let inProgress = assignments.filter { $0.statusEnum == .inProgress }.count
        let completed = assignments.filter { $0.statusEnum == .completed }.count
        let overdue = assignments.filter { $0.isOverdue }.count
        
        let completedAssignments = assignments.filter { $0.statusEnum == .completed }
        let averageScore: Double? = completedAssignments.isEmpty ? nil :
            completedAssignments.compactMap { $0.score }.reduce(0, +) / Double(completedAssignments.count)
        
        let totalTimeSpent = completedAssignments.compactMap { $0.timeSpentSeconds }.reduce(0, +)
        
        return PracticeAssignmentStats(
            total: total,
            pending: pending,
            inProgress: inProgress,
            completed: completed,
            overdue: overdue,
            averageScore: averageScore,
            totalTimeSpentSeconds: totalTimeSpent
        )
    }
    
    /// Get assignment completion stats for a classroom
    func getClassroomStats(classroomId: String) async throws -> ClassroomPracticeStats {
        let assignments = try await fetchClassroomAssignments(classroomId: classroomId)
        
        // Group by student
        let byStudent = Dictionary(grouping: assignments) { $0.studentId }
        
        var studentStats: [String: PracticeAssignmentStats] = [:]
        for (studentId, studentAssignments) in byStudent {
            let completed = studentAssignments.filter { $0.statusEnum == .completed }.count
            let pending = studentAssignments.filter { $0.statusEnum == .pending || $0.statusEnum == .inProgress }.count
            let overdue = studentAssignments.filter { $0.isOverdue }.count
            let avgScore = studentAssignments.filter { $0.statusEnum == .completed }
                .compactMap { $0.score }.reduce(0, +) / max(1, Double(completed))
            
            studentStats[studentId] = PracticeAssignmentStats(
                total: studentAssignments.count,
                pending: pending,
                inProgress: 0,
                completed: completed,
                overdue: overdue,
                averageScore: completed > 0 ? avgScore : nil,
                totalTimeSpentSeconds: 0
            )
        }
        
        return ClassroomPracticeStats(
            totalAssignments: assignments.count,
            studentCount: byStudent.count,
            studentStats: studentStats
        )
    }
    
    // MARK: - Helpers
    
    /// Check if assignment is overdue
    func isOverdue(_ assignment: PracticeAssignment) -> Bool {
        assignment.isOverdue
    }
    
    /// Get time remaining until due date
    func timeRemaining(for assignment: PracticeAssignment) -> String? {
        guard let dueDate = assignment.dueDate else { return nil }
        
        let due = dueDate.foundationDate
        let now = Date()
        
        if now > due {
            return "Overdue"
        }
        
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: now, to: due)
        
        if let days = components.day, days > 0 {
            return "\(days) day\(days == 1 ? "" : "s")"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else if let minutes = components.minute {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }
        
        return "Less than a minute"
    }
}

// MARK: - Statistics Types

struct PracticeAssignmentStats {
    let total: Int
    let pending: Int
    let inProgress: Int
    let completed: Int
    let overdue: Int
    let averageScore: Double?
    let totalTimeSpentSeconds: Int
    
    var completionRate: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total) * 100
    }
    
    var averageScoreString: String {
        guard let score = averageScore else { return "N/A" }
        return "\(Int(score))%"
    }
}

struct ClassroomPracticeStats {
    let totalAssignments: Int
    let studentCount: Int
    let studentStats: [String: PracticeAssignmentStats]
    
    var averageCompletionRate: Double {
        guard !studentStats.isEmpty else { return 0 }
        let total = studentStats.values.map { $0.completionRate }.reduce(0, +)
        return total / Double(studentStats.count)
    }
}

// MARK: - Errors

enum PracticeAssignmentError: LocalizedError {
    case noProblems
    case noStudentsInClass
    case unauthorized
    case notFound
    case alreadyCompleted
    
    var errorDescription: String? {
        switch self {
        case .noProblems:
            return "No practice problems provided"
        case .noStudentsInClass:
            return "No students found in the classroom"
        case .unauthorized:
            return "You don't have permission to perform this action"
        case .notFound:
            return "Practice assignment not found"
        case .alreadyCompleted:
            return "This assignment has already been completed"
        }
    }
}
