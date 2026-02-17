//
//  PracticeTrackingService.swift
//  PeaTutorApp
//
//  Sprint 7.4: AI-Powered Practice Generation
//  Service for tracking practice completion and updating analytics
//
//  Updated: Added PracticeAssignment support and comprehensive analytics updates
//

import Foundation
import Amplify

@MainActor
class PracticeTrackingService: ObservableObject {
    static let shared = PracticeTrackingService()
    
    private init() {}
    
    // MARK: - Record Practice Session
    
    /// Record a completed practice session and update analytics
    func recordPracticeSession(
        problems: [PracticeProblem],
        results: [PracticeResult],
        studentId: String,
        classroomId: String?
    ) async throws {
        print("📊 Recording practice session for student: \(studentId)")
        print("📊 Problems: \(problems.count), Results: \(results.count)")
        
        // Update concept mastery based on results
        try await updateMasteryFromPractice(
            results: results,
            problems: problems,
            studentId: studentId,
            classroomId: classroomId
        )
        
        // Update student progress
        try await updateStudentProgress(
            studentId: studentId,
            classroomId: classroomId,
            problemsAttempted: results.count,
            problemsCorrect: results.filter { $0.isCorrect }.count
        )
        
        // Update problem statistics
        for result in results {
            if let problem = problems.first(where: { $0.id == result.problemId }) {
                try await updateProblemStats(problem: problem, wasCorrect: result.isCorrect)
            }
        }
        
        print("✅ Practice session recorded successfully")
    }
    
    // MARK: - Record Practice Session with Assignment
    
    /// Record a completed practice session linked to a PracticeAssignment
    /// Updates the assignment, concept mastery, curriculum progress, and analytics
    func recordPracticeSessionWithAssignment(
        assignment: PracticeAssignment,
        problems: [PracticeProblem],
        results: [PracticeResult],
        timeSpentSeconds: Int
    ) async throws -> PracticeAssignment {
        let studentId = assignment.studentId
        let classroomId = assignment.classroomId
        
        print("📊 Recording practice session for assignment: \(assignment.id)")
        print("📊 Student: \(studentId)")
        print("📊 Problems: \(problems.count), Results: \(results.count)")
        
        let correctCount = results.filter { $0.isCorrect }.count
        let totalAttempted = results.count
        
        // 1. Update PracticeAssignment record
        let updatedAssignment = try await PracticeAssignmentService.shared.completeAssignment(
            assignment,
            correctCount: correctCount,
            totalAttempted: totalAttempted,
            timeSpentSeconds: timeSpentSeconds
        )
        
        // 2. Update ConceptMastery records
        try await updateMasteryFromPractice(
            results: results,
            problems: problems,
            studentId: studentId,
            classroomId: classroomId
        )
        
        // 3. Update StudentCurriculumProgress
        try await updateCurriculumProgress(
            studentId: studentId,
            classroomId: classroomId,
            problems: problems,
            results: results
        )
        
        // 4. Update StudentAnalyticsSummary
        try await updateAnalyticsSummary(
            studentId: studentId,
            classroomId: classroomId,
            problemsAttempted: totalAttempted,
            problemsCorrect: correctCount,
            timeSpentSeconds: timeSpentSeconds
        )
        
        // 5. Update StudentProgress (streaks, etc.)
        try await updateStudentProgress(
            studentId: studentId,
            classroomId: classroomId,
            problemsAttempted: totalAttempted,
            problemsCorrect: correctCount
        )
        
        // 6. Update PracticeProblem statistics
        for result in results {
            if let problem = problems.first(where: { $0.id == result.problemId }) {
                try await updateProblemStats(problem: problem, wasCorrect: result.isCorrect)
            }
        }
        
        print("✅ Practice session with assignment recorded successfully")
        return updatedAssignment
    }
    
    // MARK: - Update Concept Mastery
    
    /// Update ConceptMastery records based on practice results
    func updateMasteryFromPractice(
        results: [PracticeResult],
        problems: [PracticeProblem],
        studentId: String,
        classroomId: String?
    ) async throws {
        // Group results by concept
        var conceptResults: [String: (correct: Int, total: Int, curriculumCode: String?)] = [:]
        
        for result in results {
            guard let problem = problems.first(where: { $0.id == result.problemId }) else {
                continue
            }
            
            let concept = problem.concept
            var current = conceptResults[concept] ?? (correct: 0, total: 0, curriculumCode: problem.curriculumCode)
            current.total += 1
            if result.isCorrect {
                current.correct += 1
            }
            conceptResults[concept] = current
        }
        
        // Update mastery for each concept
        for (concept, stats) in conceptResults {
            try await updateConceptMasteryRecord(
                studentId: studentId,
                classroomId: classroomId,
                concept: concept,
                attempted: stats.total,
                correct: stats.correct,
                curriculumCode: stats.curriculumCode
            )
        }
    }
    
    private func updateConceptMasteryRecord(
        studentId: String,
        classroomId: String?,
        concept: String,
        attempted: Int,
        correct: Int,
        curriculumCode: String? = nil
    ) async throws {
        // Query for existing concept mastery
        let allMastery = try await Amplify.DataStore.query(ConceptMastery.self)
        let existingMastery = allMastery.first { mastery in
            mastery.studentId == studentId &&
            mastery.concept == concept &&
            (classroomId == nil || mastery.classroomId == classroomId)
        }
        
        if var mastery = existingMastery {
            // Update existing record
            mastery.totalAttempts += attempted
            mastery.correctAttempts += correct
            mastery.recentQuestions += attempted
            
            // ✅ FIX: Update curriculum code if not already set
            if mastery.curriculumCode == nil && curriculumCode != nil {
                mastery.curriculumCode = curriculumCode
                print("📚 Added curriculum code to existing mastery: \(curriculumCode!)")
            }
            
            // Recalculate accuracy and mastery
            mastery.accuracyRate = Double(mastery.correctAttempts) / Double(mastery.totalAttempts) * 100
            
            // Update mastery percentage using weighted average (recent performance weighted more)
            let recentAccuracy = Double(correct) / Double(attempted) * 100
            mastery.masteryPercentage = (mastery.masteryPercentage * 0.7) + (recentAccuracy * 0.3)
            
            // Update trend
            if recentAccuracy > mastery.accuracyRate {
                mastery.trend = "improving"
            } else if recentAccuracy < mastery.accuracyRate - 10 {
                mastery.trend = "declining"
            } else {
                mastery.trend = "stable"
            }
            
            mastery.lastPracticed = Temporal.DateTime.now()
            mastery.lastUpdatedAt = Temporal.DateTime.now()
            
            try await Amplify.DataStore.save(mastery)
            print("✅ Updated mastery for \(concept): \(Int(mastery.masteryPercentage))%")
        } else {
            // Create new record
            let accuracy = Double(correct) / Double(attempted) * 100
            let newMastery = ConceptMastery(
                studentId: studentId,
                classroomId: classroomId,
                concept: concept,
                gradeLevel: nil,
                masteryPercentage: accuracy,
                accuracyRate: accuracy,
                totalAttempts: attempted,
                correctAttempts: correct,
                incorrectAttempts: attempted - correct,
                trend: "stable",
                recentQuestions: attempted,
                lastPracticed: Temporal.DateTime.now(),
                easyQuestions: 0,
                mediumQuestions: attempted,
                hardQuestions: 0,
                easyCorrect: 0,
                mediumCorrect: correct,
                hardCorrect: 0,
                strengthAreas: nil,
                improvementAreas: nil,
                recommendedPractice: nil,
                curriculumCode: curriculumCode,
                calculatedAt: Temporal.DateTime.now(),
                lastUpdatedAt: Temporal.DateTime.now()
            )
            
            try await Amplify.DataStore.save(newMastery)
            print("✅ Created new mastery record for \(concept)")
        }
    }
    
    // MARK: - Update Curriculum Progress
    
    /// Update StudentCurriculumProgress based on practice results
    private func updateCurriculumProgress(
        studentId: String,
        classroomId: String?,
        problems: [PracticeProblem],
        results: [PracticeResult]
    ) async throws {
        // Get unique grade levels from problems
        let gradeLevels = Set(problems.compactMap { $0.curriculumGradeLevel })
        
        for gradeLevel in gradeLevels {
            // Always update curriculum progress
            // AnalyticsService will create a new record if none exists, or update existing
            try await AnalyticsService.shared.updateStudentCurriculumProgress(
                studentId: studentId,
                classroomId: classroomId,
                gradeLevel: gradeLevel
            )
            print("✅ Updated curriculum progress for \(gradeLevel)")
        }
    }
    
    // MARK: - Update Analytics Summary
    
    /// Update StudentAnalyticsSummary record
    private func updateAnalyticsSummary(
        studentId: String,
        classroomId: String?,
        problemsAttempted: Int,
        problemsCorrect: Int,
        timeSpentSeconds: Int
    ) async throws {
        // Query for existing analytics summary
        let allSummaries = try await Amplify.DataStore.query(StudentAnalyticsSummary.self)
        var summary = allSummaries.first { s in
            s.studentId == studentId &&
            (classroomId == nil || s.classroomId == classroomId)
        }
        
        if var existingSummary = summary {
            // Update existing record
            existingSummary.totalQuestionsAttempted += problemsAttempted
            existingSummary.totalQuestionsCorrect += problemsCorrect
            
            // Recalculate overall accuracy
            if existingSummary.totalQuestionsAttempted > 0 {
                existingSummary.overallAccuracy = Double(existingSummary.totalQuestionsCorrect) / Double(existingSummary.totalQuestionsAttempted) * 100
            }
            
            // Update timestamps
            existingSummary.lastUpdated = Temporal.DateTime.now()
            existingSummary.lastCalculated = Temporal.DateTime.now()
            
            try await Amplify.DataStore.save(existingSummary)
            print("✅ Updated analytics summary for student: \(studentId)")
        }
        // If no summary exists, it will be created by AnalyticsService on next calculation
    }
    
    // MARK: - Update Student Progress
    
    private func updateStudentProgress(
        studentId: String,
        classroomId: String?,
        problemsAttempted: Int,
        problemsCorrect: Int
    ) async throws {
        // Query for existing student progress
        let allProgress = try await Amplify.DataStore.query(StudentProgress.self)
        let existingProgress = allProgress.first { progress in
            progress.studentId == studentId &&
            (classroomId == nil || progress.classroom?.id == classroomId)
        }
        
        if var progress = existingProgress {
            // Update existing record
            progress.totalSubmissions += 1
            
            // Update streak
            let lastSubmission = progress.lastSubmissionAt?.foundationDate ?? Date.distantPast
            let daysSinceLastSubmission = Calendar.current.dateComponents(
                [.day],
                from: lastSubmission,
                to: Date()
            ).day ?? 0
            
            if daysSinceLastSubmission <= 1 {
                // Continuing streak
                let currentStreak = (progress.currentStreak ?? 0) + 1
                progress.currentStreak = currentStreak
                if currentStreak > (progress.longestStreak ?? 0) {
                    progress.longestStreak = currentStreak
                }
            } else {
                // Streak broken
                progress.currentStreak = 1
            }
            
            progress.lastSubmissionAt = Temporal.DateTime.now()
            progress.progressUpdatedAt = Temporal.DateTime.now()
            
            try await Amplify.DataStore.save(progress)
            print("✅ Updated student progress")
        }
        // Note: If no progress exists, it will be created when homework is submitted
    }
    
    // MARK: - Update Problem Statistics
    
    /// Update statistics for a practice problem
    func updateProblemStats(
        problem: PracticeProblem,
        wasCorrect: Bool
    ) async throws {
        var updated = problem
        updated.timesUsed += 1
        
        // Update average score
        let currentAvg = updated.averageScore ?? 0
        let currentCount = Double(updated.timesUsed - 1)
        let newScore = wasCorrect ? 1.0 : 0.0
        updated.averageScore = currentCount > 0 ?
            (currentAvg * currentCount + newScore) / Double(updated.timesUsed) :
            newScore
        
        try await Amplify.DataStore.save(updated)
    }
    
    // MARK: - Fetch Practice History
    
    /// Fetch practice history for a student
    func fetchPracticeHistory(
        studentId: String,
        limit: Int = 50
    ) async throws -> [PracticeProblem] {
        let allProblems = try await Amplify.DataStore.query(PracticeProblem.self)
        
        return allProblems
            .filter { $0.userId == studentId && $0.timesUsed > 0 }
            .sorted { ($0.generatedAt.foundationDate) > ($1.generatedAt.foundationDate) }
            .prefix(limit)
            .map { $0 }
    }
    
    /// Get practice statistics for a concept
    func getPracticeStatsForConcept(
        studentId: String,
        concept: String
    ) async throws -> ConceptPracticeStats {
        let allProblems = try await Amplify.DataStore.query(PracticeProblem.self)
        
        let conceptProblems = allProblems.filter {
            $0.userId == studentId &&
            $0.concept == concept &&
            $0.timesUsed > 0
        }
        
        let totalAttempts = conceptProblems.reduce(0) { $0 + $1.timesUsed }
        let avgScore = conceptProblems.isEmpty ? 0 :
            conceptProblems.reduce(0.0) { $0 + ($1.averageScore ?? 0) } / Double(conceptProblems.count)
        
        return ConceptPracticeStats(
            concept: concept,
            totalProblems: conceptProblems.count,
            totalAttempts: totalAttempts,
            averageScore: avgScore * 100, // Convert to percentage
            lastPracticed: conceptProblems.max(by: {
                $0.generatedAt.foundationDate < $1.generatedAt.foundationDate
            })?.generatedAt.foundationDate
        )
    }
}

// MARK: - Supporting Types

struct ConceptPracticeStats {
    let concept: String
    let totalProblems: Int
    let totalAttempts: Int
    let averageScore: Double // Percentage
    let lastPracticed: Date?
    
    var formattedLastPracticed: String {
        guard let date = lastPracticed else { return "Never" }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Practice Analytics Summary

struct PracticeAnalyticsSummary {
    let totalSessions: Int
    let totalProblemsAttempted: Int
    let totalCorrect: Int
    let overallAccuracy: Double
    let mostPracticedConcepts: [String]
    let conceptsNeedingWork: [String]
    let currentStreak: Int
    let totalPracticeTime: TimeInterval
    
    var accuracyTrend: String {
        if overallAccuracy >= 80 { return "improving" }
        if overallAccuracy >= 60 { return "stable" }
        return "needs focus"
    }
}

extension PracticeTrackingService {
    
    /// Generate practice analytics summary for a student
    func generatePracticeAnalytics(
        studentId: String,
        classroomId: String?
    ) async throws -> PracticeAnalyticsSummary {
        // Fetch all practice problems
        let allProblems = try await Amplify.DataStore.query(PracticeProblem.self)
        let studentProblems = allProblems.filter {
            $0.userId == studentId && $0.timesUsed > 0
        }
        
        // Fetch completed assignments for time tracking
        let assignments = try await PracticeAssignmentService.shared.fetchCompletedAssignments(studentId: studentId)
        let totalPracticeTime = TimeInterval(assignments.compactMap { $0.timeSpentSeconds }.reduce(0, +))
        
        // Calculate statistics
        let totalAttempts = studentProblems.reduce(0) { $0 + $1.timesUsed }
        let totalCorrect = studentProblems.reduce(0) { sum, problem in
            let correctPerProblem = Int((problem.averageScore ?? 0) * Double(problem.timesUsed))
            return sum + correctPerProblem
        }
        
        // Group by concept
        var conceptCounts: [String: Int] = [:]
        var conceptScores: [String: Double] = [:]
        
        for problem in studentProblems {
            conceptCounts[problem.concept, default: 0] += problem.timesUsed
            let currentScore = conceptScores[problem.concept, default: 0]
            let newScore = (problem.averageScore ?? 0) * 100
            conceptScores[problem.concept] = (currentScore + newScore) / 2
        }
        
        let mostPracticed = conceptCounts.sorted { $0.value > $1.value }
            .prefix(3).map { $0.key }
        
        let needsWork = conceptScores.filter { $0.value < 70 }
            .sorted { $0.value < $1.value }
            .prefix(3).map { $0.key }
        
        // Get student progress for streak
        let allProgress = try await Amplify.DataStore.query(StudentProgress.self)
        let progress = allProgress.first { $0.studentId == studentId }
        
        return PracticeAnalyticsSummary(
            totalSessions: assignments.count,
            totalProblemsAttempted: totalAttempts,
            totalCorrect: totalCorrect,
            overallAccuracy: totalAttempts > 0 ? Double(totalCorrect) / Double(totalAttempts) * 100 : 0,
            mostPracticedConcepts: Array(mostPracticed),
            conceptsNeedingWork: Array(needsWork),
            currentStreak: progress?.currentStreak ?? 0,
            totalPracticeTime: totalPracticeTime
        )
    }
}
