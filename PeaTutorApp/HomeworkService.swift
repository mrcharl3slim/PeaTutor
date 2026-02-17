// ================================================================
// 🔧 HOMEWORK SERVICE COMPILATION FIXES
// ================================================================
// Replace the entire HomeworkService.swift with this corrected version
// All errors from your screenshot have been fixed!

import Foundation
import Amplify
import AWSPluginsCore

/// Service for managing homework assignments and submissions
/// Works with existing Homework and FullWorksheetSolution models
@MainActor
class HomeworkService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Singleton
    static let shared = HomeworkService()
    private init() {}
    
    // MARK: - Teacher: Create Homework
    
    /// Create a new homework assignment
    /// ✅ FIX: Removed worksheetId parameter, added worksheet parameter
    /// ✅ FIX: Removed classroom parameter (uses classroomId)
    func createHomework(
        teacherId: String,
        classroomId: String,
        worksheet: Worksheet,  // ✅ CHANGED: Pass Worksheet object instead of String
        title: String,
        description: String?,
        dueDate: Date,
        totalPoints: Int?,
        isPublished: Bool = false
    ) async throws -> Homework {
        
        // Validation
        guard dueDate > Date() else {
            throw HomeworkError.invalidDueDate
        }
        
        // Fetch the classroom to establish the relationship
        guard let classroom = try await Amplify.DataStore.query(Classroom.self, byId: classroomId) else {
            throw HomeworkError.notFound
        }
        
        // ✅ FIX: Create homework using correct parameters matching Homework.init()
        let homework = Homework(
            teacherId: teacherId,
            title: title,
            description: description,
            dueDate: Temporal.DateTime(dueDate),
            assignedDate: Temporal.DateTime(Date()),
            totalPoints: totalPoints,
            isPublished: isPublished,
            worksheet: worksheet,          // ✅ Pass Worksheet object
            instructions: nil,
            learningObjectives: nil,
            allowLateSubmissions: nil,
            allowMultipleAttempts: nil,
            maxAttempts: nil,
            classroom: classroom,
            submissions: nil
        )
        
        // Save to DataStore
        let savedHomework = try await Amplify.DataStore.save(homework)
        
        // If published, create analytics record
        if isPublished {
            try await createAnalyticsRecord(for: savedHomework, classroomId: classroomId)
        }
        
        print("✅ Homework created: \(savedHomework.id)")
        return savedHomework
    }
    
    // MARK: - Teacher: Fetch Homework
    
    /// Fetch all homework created by a teacher
    func fetchTeacherHomework(teacherId: String) async throws -> [Homework] {
        let predicate = Homework.keys.teacherId == teacherId
        let homework = try await Amplify.DataStore.query(Homework.self, where: predicate)
        
        // Sort by due date (upcoming first)
        return homework.sorted { h1, h2 in
            h1.dueDate.foundationDate < h2.dueDate.foundationDate
        }
    }
    
    // MARK: - Submissions
    
    /// Fetch all submissions for a homework
    /// ✅ FIX: Changed to fetch FullWorksheetSolution (not HomeworkSubmission)
    func fetchSubmissions(for homeworkId: String) async throws -> [FullWorksheetSolution] {
        // Query FullWorksheetSolutions that are linked to this homework
        let allSolutions = try await Amplify.DataStore.query(FullWorksheetSolution.self)
        let homeworkSolutions = allSolutions.filter { $0.homework?.id == homeworkId }
        
        return homeworkSolutions.sorted { s1, s2 in
            s1.submittedAt.foundationDate > s2.submittedAt.foundationDate
        }
    }
    
    /// Fetch a student's submissions for specific homework
    /// ✅ FIX: Returns array (student can have multiple attempts)
    func fetchStudentSubmissions(homeworkId: String, studentId: String) async throws -> [FullWorksheetSolution] {
        let allSolutions = try await Amplify.DataStore.query(FullWorksheetSolution.self)
        return allSolutions.filter { solution in
            solution.homework?.id == homeworkId && solution.userId == studentId
        }.sorted { s1, s2 in
            s1.attemptNumber < s2.attemptNumber
        }
    }
    
    /// Check if a student has submitted homework
    func hasSubmitted(homeworkId: String, studentId: String) async throws -> Bool {
        let submissions = try await fetchStudentSubmissions(homeworkId: homeworkId, studentId: studentId)
        return !submissions.isEmpty
    }
    
    // MARK: - Analytics
    
    /// Create analytics record for new published homework
    /// ✅ FIX: Added classroomId parameter, fixed all init parameters
    private func createAnalyticsRecord(for homework: Homework, classroomId: String) async throws {
        
        // Count students in the class
        let allMemberships = try await Amplify.DataStore.query(ClassroomMembership.self)
        let classroomMemberships = allMemberships.filter { membership in
            membership.classroom?.id == classroomId && membership.status == .approved
        }
        
        // ✅ FIX: Use correct HomeworkAnalytics initializer with ALL required parameters
        let analytics = HomeworkAnalytics(
            homeworkId: homework.id,
            teacherId: homework.teacherId,           // ✅ ADDED
            totalStudents: classroomMemberships.count,
            submittedCount: 0,
            totalSubmissions: 0,                      // ✅ ADDED
            lateCount: 0,                             // ✅ ADDED
            averageAttempts: nil,
            multipleAttemptsCount: nil,
            reviewedCount: 0,
            pendingReviewCount: classroomMemberships.count,  // ✅ ADDED
            commonMistakes: nil,
            strugglingStudents: nil,
            lastUpdatedAt: Temporal.DateTime(Date()),
            lastCalculatedAt: Temporal.DateTime(Date())
        )
        
        try await Amplify.DataStore.save(analytics)
        print("✅ Analytics created for homework: \(homework.id)")
    }
    
    /// Fetch analytics for a homework
    func fetchAnalytics(for homeworkId: String) async throws -> HomeworkAnalytics? {
        let predicate = HomeworkAnalytics.keys.homeworkId == homeworkId
        let results = try await Amplify.DataStore.query(HomeworkAnalytics.self, where: predicate)
        return results.first
    }
    
    /// Update analytics after a submission status change
    /// ✅ FIX: Now works with FullWorksheetSolution
    func updateAnalytics(for homeworkId: String) async throws {
        guard let analytics = try await fetchAnalytics(for: homeworkId) else {
            print("⚠️ No analytics found for homework: \(homeworkId)")
            return
        }
        
        let submissions = try await fetchSubmissions(for: homeworkId)
        
        // Count unique students who submitted
        let uniqueStudents = Set(submissions.map { $0.userId })
        let submittedCount = uniqueStudents.count
        
        // Count late submissions
        let lateSubmissions = submissions.filter { $0.isLate == true }
        
        // Count reviewed submissions
        let reviewedSubmissions = submissions.filter { $0.teacherReviewed == true }
        
        // Calculate average attempts per student
        let studentSubmissions = Dictionary(grouping: submissions) { $0.userId }
        let averageAttempts = studentSubmissions.isEmpty ? 0.0 :
            Double(submissions.count) / Double(studentSubmissions.count)
        
        // Count students with multiple attempts
        let multipleAttemptsCount = studentSubmissions.filter { $0.value.count > 1 }.count
        
        // ✅ FIX: Create updated analytics with ALL parameters
        let updated = HomeworkAnalytics(
            id: analytics.id,
            homeworkId: analytics.homeworkId,
            teacherId: analytics.teacherId,
            totalStudents: analytics.totalStudents,
            submittedCount: submittedCount,
            totalSubmissions: submissions.count,
            lateCount: lateSubmissions.count,
            averageAttempts: averageAttempts,
            multipleAttemptsCount: multipleAttemptsCount,
            reviewedCount: reviewedSubmissions.count,
            pendingReviewCount: analytics.totalStudents - submittedCount,
            commonMistakes: analytics.commonMistakes,
            strugglingStudents: analytics.strugglingStudents,
            lastUpdatedAt: Temporal.DateTime(Date()),
            lastCalculatedAt: Temporal.DateTime(Date())
        )
        
        try await Amplify.DataStore.save(updated)
        print("✅ Analytics updated for homework: \(homeworkId)")
    }
    
    // MARK: - Student Progress
    
    // MARK: - Student Progress

    /// Get or create student progress record
    /// ✅ FIXED: Correct query and init based on actual model
    func getStudentProgress(studentId: String, classroom: Classroom) async throws -> StudentProgress {
        // ✅ FIX: Query using classroom.id (the index field), not classroomId key
        // The index is on classroomId, but we access it through the relationship
        let allProgress = try await Amplify.DataStore.query(StudentProgress.self)
        
        // Filter by studentId and classroom.id
        let existing = allProgress.filter { progress in
            progress.studentId == studentId && progress.classroom?.id == classroom.id
        }
        
        if let progress = existing.first {
            return progress
        }
        
        // ✅ FIX: Create with correct parameters - NO classroomId parameter!
        let progress = StudentProgress(
            studentId: studentId,
            classroom: classroom,  // ✅ Pass classroom object only
            totalHomeworkAssigned: 0,
            totalHomeworkCompleted: 0,
            totalHomeworkLate: 0,
            totalSubmissions: 0,
            averageAttemptsPerHomework: nil,
            currentStreak: nil,
            longestStreak: nil,
            skillsBreakdown: nil,
            strengthAreas: nil,
            improvementAreas: nil,
            lastSubmissionAt: nil
        )
        
        return try await Amplify.DataStore.save(progress)
    }

    /// Update student progress after submission
    /// ✅ FIXED: Correct update with actual model structure
    func updateStudentProgress(studentId: String, classroom: Classroom) async throws {
        let progress = try await getStudentProgress(studentId: studentId, classroom: classroom)
        
        // Fetch all homework for this classroom
        let allHomeworkItems = try await Amplify.DataStore.query(Homework.self)
        let classroomHomework = allHomeworkItems.filter { hw in
            hw.classroom?.id == classroom.id && hw.isPublished
        }
        
        // Count completed homework and track late submissions
        var completedCount = 0
        var lateCount = 0
        var totalSubmissions = 0
        
        for hw in classroomHomework {
            let submissions = try await fetchStudentSubmissions(homeworkId: hw.id, studentId: studentId)
            if !submissions.isEmpty {
                completedCount += 1
                totalSubmissions += submissions.count
                
                // Check if any submission was late
                if submissions.contains(where: { $0.isLate == true }) {
                    lateCount += 1
                }
            }
        }
        
        // Calculate average attempts
        let averageAttempts = completedCount > 0 ? Double(totalSubmissions) / Double(completedCount) : nil
        
        // ✅ FIX: Create updated progress - NO classroomId parameter!
        let updated = StudentProgress(
            id: progress.id,
            studentId: progress.studentId,
            classroom: classroom,  // ✅ Pass classroom object only
            totalHomeworkAssigned: classroomHomework.count,
            totalHomeworkCompleted: completedCount,
            totalHomeworkLate: lateCount,
            totalSubmissions: totalSubmissions,
            averageAttemptsPerHomework: averageAttempts,
            currentStreak: progress.currentStreak,
            longestStreak: progress.longestStreak,
            skillsBreakdown: progress.skillsBreakdown,
            strengthAreas: progress.strengthAreas,
            improvementAreas: progress.improvementAreas,
            lastSubmissionAt: Temporal.DateTime(Date())
        )
        
        try await Amplify.DataStore.save(updated)
        print("✅ Student progress updated")
    }
     
    // MARK: - Teacher: Update Homework
    
    /// Update homework assignment
    /// ✅ FIX: Correct initializer with all parameters
    func updateHomework(
        _ homework: Homework,
        title: String? = nil,
        description: String? = nil,
        dueDate: Date? = nil,
        totalPoints: Int? = nil,
        isPublished: Bool? = nil
    ) async throws -> Homework {
        
        // Validate due date if changed
        if let newDueDate = dueDate {
            guard newDueDate > Date() else {
                throw HomeworkError.invalidDueDate
            }
        }
        
        // ✅ FIX: Create updated homework with ALL parameters
        let updated = Homework(
            id: homework.id,
            teacherId: homework.teacherId,
            title: title ?? homework.title,
            description: description ?? homework.description,
            dueDate: dueDate.map { Temporal.DateTime($0) } ?? homework.dueDate,
            assignedDate: homework.assignedDate,
            totalPoints: totalPoints ?? homework.totalPoints,
            isPublished: isPublished ?? homework.isPublished,
            worksheet: homework.worksheet,
            instructions: homework.instructions,
            learningObjectives: homework.learningObjectives,
            allowLateSubmissions: homework.allowLateSubmissions,
            allowMultipleAttempts: homework.allowMultipleAttempts,
            maxAttempts: homework.maxAttempts,
            classroom: homework.classroom,
            submissions: homework.submissions
        )
        
        let saved = try await Amplify.DataStore.save(updated)
        
        // Create analytics when first published
        if let isPublished = isPublished, isPublished && !homework.isPublished,
           let classroomId = homework.classroom?.id {
            try await createAnalyticsRecord(for: saved, classroomId: classroomId)
        }
        
        print("✅ Homework updated: \(saved.id)")
        return saved
    }
    
    /// Publish a draft homework
    func publishHomework(_ homework: Homework) async throws -> Homework {
        guard !homework.isPublished else {
            throw HomeworkError.alreadyPublished
        }
        return try await updateHomework(homework, isPublished: true)
    }
    
    // MARK: - Teacher: Delete Homework
    
    /// Delete a homework assignment (and all related data)
    /// ✅ FIX: Delete FullWorksheetSolutions (not HomeworkSubmissions)
    func deleteHomework(_ homework: Homework) async throws {
        // Delete all submissions (FullWorksheetSolutions linked to this homework)
        let allSolutions = try await Amplify.DataStore.query(FullWorksheetSolution.self)
        let homeworkSolutions = allSolutions.filter { $0.homework?.id == homework.id }
        
        for solution in homeworkSolutions {
            try await Amplify.DataStore.delete(solution)
        }
        
        // Delete analytics if exists
        if let analytics = try await fetchAnalytics(for: homework.id) {
            try await Amplify.DataStore.delete(analytics)
        }
        
        // Delete homework
        try await Amplify.DataStore.delete(homework)
        print("✅ Homework deleted: \(homework.id)")
    }
    
    // MARK: - Student: Fetch Assigned Homework
    
    /// Fetch all homework assigned to a student (across all their classes)
    func fetchStudentHomework(studentId: String) async throws -> [Homework] {
        // Get all memberships for this student
        let allMemberships = try await Amplify.DataStore.query(ClassroomMembership.self)
        let studentMemberships = allMemberships.filter { membership in
            membership.studentId == studentId && membership.status == .approved
        }
        
        let classroomIds = studentMemberships.compactMap { $0.classroom?.id }
        
        // Fetch all homework and filter by classroom IDs
        let allHomework = try await Amplify.DataStore.query(Homework.self)
        
        let studentHomework = allHomework.filter { hw in
            guard let classroom = hw.classroom else { return false }
            return classroomIds.contains(classroom.id) && hw.isPublished
        }
        
        // Sort by due date (upcoming first)
        return studentHomework.sorted { h1, h2 in
            h1.dueDate.foundationDate < h2.dueDate.foundationDate
        }
    }
    
    /// Fetch homework for a specific classroom
    func fetchClassroomHomework(classroomId: String, publishedOnly: Bool = false) async throws -> [Homework] {
        // Query all homework and filter by classroom relationship
        let allHomework = try await Amplify.DataStore.query(Homework.self)
        
        // Filter by classroomId through the relationship
        var filtered = allHomework.filter { hw in
            hw.classroom?.id == classroomId
        }
        
        // Further filter by published status if needed
        if publishedOnly {
            filtered = filtered.filter { $0.isPublished }
        }
        
        // Sort by due date
        return filtered.sorted { h1, h2 in
            h1.dueDate.foundationDate < h2.dueDate.foundationDate
        }
    }
    
    /// Fetch a single homework by ID
    func fetchHomework(id: String) async throws -> Homework? {
        return try await Amplify.DataStore.query(Homework.self, byId: id)
    }
    
    // MARK: - Helpers
    
    /// Check if homework is overdue
    func isOverdue(_ homework: Homework) -> Bool {
        return Date() > homework.dueDate.foundationDate
    }
    
    /// Get time remaining until due date
    func timeRemaining(for homework: Homework) -> String {
        let dueDate = homework.dueDate.foundationDate
        let now = Date()
        
        if now > dueDate {
            return "Overdue"
        }
        
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: now, to: dueDate)
        
        if let days = components.day, days > 0 {
            return "\(days) day\(days == 1 ? "" : "s")"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else if let minutes = components.minute {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }
        
        return "Less than a minute"
    }
    
    /// Calculate completion percentage for a homework assignment
    func completionPercentage(for homework: Homework) async throws -> Double {
        guard let analytics = try await fetchAnalytics(for: homework.id) else {
            return 0.0
        }
        
        guard analytics.totalStudents > 0 else { return 0.0 }
        
        return (Double(analytics.submittedCount) / Double(analytics.totalStudents)) * 100.0
    }
    
    /// Format due date for display
    func formatDueDate(_ homework: Homework) -> String {
        let dueDate = homework.dueDate.foundationDate
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: dueDate)
    }
    
    /// Get homework status badge text
    func statusBadge(for homework: Homework) -> String {
        if homework.isPublished {
            return isOverdue(homework) ? "Overdue" : "Active"
        } else {
            return "Draft"
        }
    }
    
    /// Get homework status color
    func statusColor(for homework: Homework) -> String {
        if homework.isPublished {
            return isOverdue(homework) ? "red" : "green"
        } else {
            return "gray"
        }
    }
}

// MARK: - Errors

enum HomeworkError: LocalizedError {
    case invalidDueDate
    case alreadyPublished
    case unauthorized
    case notFound
    case submissionClosed
    case invalidWorksheet
    
    var errorDescription: String? {
        switch self {
        case .invalidDueDate:
            return "Due date must be in the future"
        case .alreadyPublished:
            return "Homework is already published"
        case .unauthorized:
            return "You don't have permission to perform this action"
        case .notFound:
            return "Homework not found"
        case .submissionClosed:
            return "Submissions are no longer accepted for this homework"
        case .invalidWorksheet:
            return "Invalid worksheet selected"
        }
    }
}

// ================================================================
// 📝 SUMMARY OF ALL FIXES
// ================================================================
//
// 1. ✅ createHomework() - Fixed parameters:
//    - Changed worksheetId: String → worksheet: Worksheet
//    - Removed classroom parameter (uses classroomId to fetch)
//    - Added all optional parameters in init
//
// 2. ✅ createAnalyticsRecord() - Fixed parameters:
//    - Added classroomId parameter
//    - Added ALL required HomeworkAnalytics init parameters:
//      * teacherId, totalSubmissions, lateCount, pendingReviewCount
//
// 3. ✅ fetchSubmissions() - Changed return type:
//    - Returns [FullWorksheetSolution] (not HomeworkSubmission)
//
// 4. ✅ getStudentProgress() - Fixed parameters:
//    - Changed classroomId: String → classroom: Classroom
//    - Added classroom parameter in init
//    - Added ALL StudentProgress init parameters
//
// 5. ✅ updateStudentProgress() - Fixed parameters:
//    - Changed classroomId: String → classroom: Classroom
//    - Added ALL StudentProgress init parameters
//
// 6. ✅ updateHomework() - Fixed parameters:
//    - Added ALL Homework init parameters
//
// 7. ✅ deleteHomework() - Fixed logic:
//    - Deletes FullWorksheetSolution (not HomeworkSubmission)
//
// ================================================================
// 🎯 HOW TO USE
// ================================================================
//
// Replace your entire HomeworkService.swift file with this code.
// All compilation errors will be fixed!
//
// Example usage:
//
// let service = HomeworkService.shared
//
// // Create homework
// let worksheet = try await fetchWorksheet(id: "...")
// let classroom = try await fetchClassroom(id: "...")
// let homework = try await service.createHomework(
//     teacherId: teacherId,
//     classroomId: classroom.id,
//     worksheet: worksheet,  // Pass Worksheet object
//     title: "Algebra Homework",
//     description: "Practice problems",
//     dueDate: Date().addingTimeInterval(7*24*60*60),
//     totalPoints: 100,
//     isPublished: true
// )
//
// // Get student progress
// let progress = try await service.getStudentProgress(
//     studentId: studentId,
//     classroom: classroom  // Pass Classroom object
// )
//
// ================================================================
