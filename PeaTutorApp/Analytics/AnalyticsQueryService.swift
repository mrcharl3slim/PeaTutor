//
//  AnalyticsQueryService.swift
//  PeaTutorApp
//
//  Sprint 7.2: Teacher Analytics Dashboard
//  Service for querying and processing student analytics data
//

import Foundation
import Amplify

@MainActor
class AnalyticsQueryService: ObservableObject {
    static let shared = AnalyticsQueryService()
    
    private init() {}
    
    // MARK: - Concept Mastery Queries
    
    /// Fetch all concept mastery records for a student
    func fetchConceptMastery(
        studentId: String,
        classroomId: String? = nil
    ) async throws -> [ConceptMastery] {
        print("📊 Fetching concept mastery for student: \(studentId)")
        
        let allMastery = try await Amplify.DataStore.query(ConceptMastery.self)
        let filtered = allMastery.filter { mastery in
            mastery.studentId == studentId &&
            (classroomId == nil || mastery.classroomId == classroomId)
        }
        
        // Sort by mastery percentage (highest first)
        return filtered.sorted { $0.masteryPercentage > $1.masteryPercentage }
    }
    
    /// Fetch concept mastery for a specific concept
    func fetchConceptMastery(
        studentId: String,
        concept: String,
        classroomId: String? = nil
    ) async throws -> ConceptMastery? {
        let allMastery = try await Amplify.DataStore.query(ConceptMastery.self)
        return allMastery.first { mastery in
            mastery.studentId == studentId &&
            mastery.concept == concept &&
            (classroomId == nil || mastery.classroomId == classroomId)
        }
    }
    
    /// Get concepts grouped by mastery level
    func getConceptsByMasteryLevel(
        studentId: String,
        classroomId: String? = nil
    ) async throws -> [MasteryLevel: [ConceptMastery]] {
        let concepts = try await fetchConceptMastery(studentId: studentId, classroomId: classroomId)
        
        var grouped: [MasteryLevel: [ConceptMastery]] = [
            .mastered: [],
            .developing: [],
            .emerging: [],
            .needsWork: []
        ]
        
        for concept in concepts {
            grouped[concept.masteryLevel, default: []].append(concept)
        }
        
        return grouped
    }
    
    // MARK: - Error Pattern Queries
    
    /// Fetch all error patterns for a student
    func fetchErrorPatterns(
        studentId: String,
        classroomId: String? = nil,
        activeOnly: Bool = false,
        resolvedOnly: Bool = false
    ) async throws -> [ErrorPattern] {
        print("🔍 Fetching error patterns for student: \(studentId)")
        
        let allErrors = try await Amplify.DataStore.query(ErrorPattern.self)
        var filtered = allErrors.filter { error in
            error.studentId == studentId &&
            (classroomId == nil || error.classroomId == classroomId)
        }
        
        // Apply filters
        if activeOnly {
            filtered = filtered.filter { $0.isActive }
        }
        
        if resolvedOnly {
            filtered = filtered.filter { $0.isResolved }
        }
        
        // Sort by severity (high -> medium -> low) then by occurrence count
        return filtered.sorted { error1, error2 in
            if error1.severityLevel.priority != error2.severityLevel.priority {
                return error1.severityLevel.priority > error2.severityLevel.priority
            }
            return error1.occurrenceCount > error2.occurrenceCount
        }
    }
    
    /// Get error patterns grouped by severity
    func getErrorsBySeverity(
        studentId: String,
        classroomId: String? = nil
    ) async throws -> [ErrorSeverity: [ErrorPattern]] {
        let errors = try await fetchErrorPatterns(studentId: studentId, classroomId: classroomId, activeOnly: true)
        
        var grouped: [ErrorSeverity: [ErrorPattern]] = [
            .high: [],
            .medium: [],
            .low: []
        ]
        
        for error in errors {
            grouped[error.severityLevel, default: []].append(error)
        }
        
        return grouped
    }
    
    /// Get error patterns filtered by concept
    func fetchErrorPatterns(
        studentId: String,
        concept: String,
        classroomId: String? = nil
    ) async throws -> [ErrorPattern] {
        let allErrors = try await fetchErrorPatterns(studentId: studentId, classroomId: classroomId)
        return allErrors.filter { error in
            error.affectedConcepts.contains(concept)
        }
    }
    
    // MARK: - Cognitive Skills Profile
    
    /// Calculate cognitive skills profile from concept mastery data
    func calculateCognitiveProfile(
        studentId: String,
        classroomId: String? = nil
    ) async throws -> CognitiveProfile {
        let concepts = try await fetchConceptMastery(studentId: studentId, classroomId: classroomId)
        
        // Map concepts to cognitive skills
        let computationConcepts = concepts.filter { ["Addition", "Subtraction", "Multiplication", "Division"].contains($0.concept) }
        let wordProblemConcepts = concepts.filter { $0.concept.contains("Word") || $0.concept.contains("Problem") }
        let reasoningConcepts = concepts.filter { ["Algebra", "Patterns", "Logic"].contains($0.concept) }
        
        // Calculate averages
        let computation = average(concepts: computationConcepts)
        let wordProblems = average(concepts: wordProblemConcepts)
        let problemSolving = average(concepts: concepts.filter { $0.concept.contains("Solving") })
        let reasoning = average(concepts: reasoningConcepts)
        
        // Calculate accuracy from overall concept data
        let totalAttempts = concepts.reduce(0) { $0 + $1.totalAttempts }
        let totalCorrect = concepts.reduce(0) { $0 + $1.correctAttempts }
        let accuracy = totalAttempts > 0 ? (Double(totalCorrect) / Double(totalAttempts)) * 100 : 0
        
        return CognitiveProfile(
            computation: computation,
            wordProblems: wordProblems,
            problemSolving: problemSolving,
            reasoning: reasoning,
            accuracy: accuracy
        )
    }
    
    /// Helper to calculate average mastery for a set of concepts
    private func average(concepts: [ConceptMastery]) -> Double {
        guard !concepts.isEmpty else { return 0 }
        let sum = concepts.reduce(0.0) { $0 + $1.masteryPercentage }
        return sum / Double(concepts.count)
    }
    
    // MARK: - Student Analytics Summary
    
    /// Fetch or calculate student analytics summary
    func fetchStudentSummary(
        studentId: String,
        classroomId: String? = nil
    ) async throws -> StudentAnalyticsSummary {
        // Try to fetch existing summary
        let allSummaries = try await Amplify.DataStore.query(StudentAnalyticsSummary.self)
        if let existing = allSummaries.first(where: {
            $0.studentId == studentId &&
            (classroomId == nil || $0.classroomId == classroomId)
        }) {
            // Check if summary is recent (within last 24 hours)
            let hoursSinceUpdate = Calendar.current.dateComponents(
                [.hour],
                from: existing.lastCalculated.foundationDate,
                to: Date()
            ).hour ?? 0
            
            if hoursSinceUpdate < 24 {
                print("✅ Using cached analytics summary")
                return existing
            }
        }
        
        // Calculate fresh summary
        print("🔄 Calculating new analytics summary")
        return try await AnalyticsService.shared.calculateStudentSummary(
            studentId: studentId,
            classroomId: classroomId
        )
    }
    
    // MARK: - Class-Wide Analytics
    
    /// Get all students needing help (bottom 20% or mastery < 60%)
    func getStudentsNeedingHelp(
        classroomId: String,
        threshold: Double = 60.0
    ) async throws -> [StudentWithProgress] {
        // Get all classroom members
        let allMembers = try await Amplify.DataStore.query(ClassroomMembership.self)
        let classMembers = allMembers.filter {
            $0.classroom?.id == classroomId && $0.status == .approved
        }
        
        var studentsWithProgress: [StudentWithProgress] = []
        
        for member in classMembers {
            // Fetch concept mastery for this student
            let concepts = try await fetchConceptMastery(
                studentId: member.studentId,
                classroomId: classroomId
            )
            
            // Calculate overall progress
            guard !concepts.isEmpty else { continue }
            let overallProgress = concepts.reduce(0.0) { $0 + $1.masteryPercentage } / Double(concepts.count)
            
            // Get active error count
            let errors = try await fetchErrorPatterns(
                studentId: member.studentId,
                classroomId: classroomId,
                activeOnly: true
            )
            
            // Fetch profile
            let profile = try await DataStoreService.shared.fetchUserProfile(userId: member.studentId)
            
            studentsWithProgress.append(StudentWithProgress(
                studentId: member.studentId,
                profile: profile,
                overallProgress: overallProgress,
                conceptCount: concepts.count,
                errorCount: errors.count,
                highSeverityErrorCount: errors.filter { $0.severityLevel == .high }.count
            ))
        }
        
        // Filter and sort
        return studentsWithProgress
            .filter { $0.overallProgress < threshold || $0.highSeverityErrorCount > 0 }
            .sorted { $0.overallProgress < $1.overallProgress }
    }
    
    /// Get most common errors across a class
    func getClassWideErrorPatterns(classroomId: String) async throws -> [ErrorPatternSummary] {
        // Get all classroom members
        let allMembers = try await Amplify.DataStore.query(ClassroomMembership.self)
        let classMembers = allMembers.filter {
            $0.classroom?.id == classroomId && $0.status == .approved
        }
        
        var errorCounts: [String: ErrorPatternSummary] = [:]
        
        for member in classMembers {
            let errors = try await fetchErrorPatterns(
                studentId: member.studentId,
                classroomId: classroomId,
                activeOnly: true
            )
            
            for error in errors {
                let key = error.errorType
                if var summary = errorCounts[key] {
                    summary.studentCount += 1
                    summary.totalOccurrences += error.occurrenceCount
                    errorCounts[key] = summary
                } else {
                    errorCounts[key] = ErrorPatternSummary(
                        errorType: error.errorType,
                        errorCategory: error.errorCategory,
                        studentCount: 1,
                        totalOccurrences: error.occurrenceCount,
                        severity: error.severityLevel
                    )
                }
            }
        }
        
        return Array(errorCounts.values)
            .sorted { $0.studentCount > $1.studentCount }
    }
}

// MARK: - Supporting Types

struct CognitiveProfile: Identifiable {
    let id = UUID()
    let computation: Double
    let wordProblems: Double
    let problemSolving: Double
    let reasoning: Double
    let accuracy: Double
    
    var radarChartData: [(skill: String, value: Double)] {
        [
            ("Computation", computation),
            ("Word Problems", wordProblems),
            ("Problem Solving", problemSolving),
            ("Reasoning", reasoning),
            ("Accuracy", accuracy)
        ]
    }
}

struct StudentWithProgress: Identifiable {
    let id = UUID()
    let studentId: String
    let profile: UserProfile?
    let overallProgress: Double
    let conceptCount: Int
    let errorCount: Int
    let highSeverityErrorCount: Int
}

struct ErrorPatternSummary: Identifiable {
    let id = UUID()
    let errorType: String
    let errorCategory: String
    var studentCount: Int
    var totalOccurrences: Int
    let severity: ErrorSeverity
}
