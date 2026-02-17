//
//  PracticeSessionViewModel.swift
//  PeaTutorApp
//
//  Sprint 7.4: AI-Powered Practice Generation
//  ViewModel for managing practice session state
//
//  Updated: Added PracticeAssignment support for tracking and analytics
//

import Foundation
import SwiftUI
import Amplify

@MainActor
class PracticeSessionViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var problems: [PracticeProblem]
    @Published var currentIndex: Int = 0
    @Published var currentHintLevel: Int = 0
    @Published var studentAnswer: String = ""
    @Published var showFeedback: Bool = false
    @Published var isCorrect: Bool?
    @Published var sessionComplete: Bool = false
    @Published var isSubmitting: Bool = false
    
    // Session metrics
    @Published var correctCount: Int = 0
    @Published var totalAttempted: Int = 0
    @Published var hintsUsedTotal: Int = 0
    @Published var problemResults: [PracticeResult] = []
    
    // Timing
    @Published var sessionStartTime: Date = Date()
    @Published var currentProblemStartTime: Date = Date()
    
    // Assignment tracking
    @Published var assignment: PracticeAssignment?
    @Published var completedAssignment: PracticeAssignment?
    
    let child: UserProfile?
    let config: PracticeSessionConfig
    
    // Callback for when assignment is completed
    var onAssignmentComplete: ((PracticeAssignment) -> Void)?
    
    // MARK: - Computed Properties
    
    var currentProblem: PracticeProblem? {
        guard currentIndex < problems.count else { return nil }
        return problems[currentIndex]
    }
    
    var progress: Double {
        guard !problems.isEmpty else { return 0 }
        return Double(currentIndex) / Double(problems.count)
    }
    
    var completedProgress: Double {
        guard !problems.isEmpty else { return 0 }
        return Double(totalAttempted) / Double(problems.count)
    }
    
    var accuracy: Double {
        guard totalAttempted > 0 else { return 0 }
        return Double(correctCount) / Double(totalAttempted) * 100
    }
    
    var totalTimeSpent: TimeInterval {
        Date().timeIntervalSince(sessionStartTime)
    }
    
    var currentProblemTimeSpent: TimeInterval {
        Date().timeIntervalSince(currentProblemStartTime)
    }
    
    var availableHints: [String] {
        guard let problem = currentProblem,
              let hints = problem.hints else { return [] }
        return hints.compactMap { $0 }
    }
    
    var visibleHints: [String] {
        Array(availableHints.prefix(currentHintLevel))
    }
    
    var hasMoreHints: Bool {
        currentHintLevel < availableHints.count
    }
    
    var canGoNext: Bool {
        currentIndex < problems.count - 1
    }
    
    var canGoPrevious: Bool {
        currentIndex > 0
    }
    
    var isLastProblem: Bool {
        currentIndex == problems.count - 1
    }
    
    /// Whether this session is linked to a PracticeAssignment
    var hasAssignment: Bool {
        assignment != nil
    }
    
    // MARK: - Initialization
    
    init(
        problems: [PracticeProblem],
        child: UserProfile?,
        config: PracticeSessionConfig = .default,
        assignment: PracticeAssignment? = nil,
        onAssignmentComplete: ((PracticeAssignment) -> Void)? = nil
    ) {
        self.problems = problems
        self.child = child
        self.config = config
        self.assignment = assignment
        self.onAssignmentComplete = onAssignmentComplete
        self.sessionStartTime = Date()
        self.currentProblemStartTime = Date()
    }
    
    // MARK: - Actions
    
    /// Submit the current answer
    func submitAnswer() async {
        guard let problem = currentProblem else { return }
        guard !studentAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSubmitting = true
        
        // Simple answer comparison (case-insensitive, whitespace-normalized)
        let normalizedStudent = normalizeAnswer(studentAnswer)
        let normalizedCorrect = normalizeAnswer(problem.answer)
        
        let correct = normalizedStudent == normalizedCorrect
        
        // Record result
        let result = PracticeResult(
            problemId: problem.id,
            isCorrect: correct,
            hintsUsed: currentHintLevel,
            timeSpentSeconds: Int(currentProblemTimeSpent),
            studentAnswer: studentAnswer
        )
        problemResults.append(result)
        
        // Update metrics
        totalAttempted += 1
        if correct {
            correctCount += 1
        }
        hintsUsedTotal += currentHintLevel
        
        // Show feedback
        isCorrect = correct
        showFeedback = true
        isSubmitting = false
        
        // Update problem usage stats
        await updateProblemStats(problem: problem, wasCorrect: correct)
        
        // Update assignment progress (if linked)
        if hasAssignment {
            await updateAssignmentProgress()
        }
    }
    
    /// Reveal the next hint
    func revealNextHint() {
        guard hasMoreHints else { return }
        withAnimation(.spring(response: 0.3)) {
            currentHintLevel += 1
        }
    }
    
    /// Move to the next problem
    func nextProblem() {
        guard canGoNext else {
            completeSession()
            return
        }
        
        withAnimation(.easeInOut) {
            currentIndex += 1
            resetProblemState()
        }
    }
    
    /// Move to the previous problem (for review)
    func previousProblem() {
        guard canGoPrevious else { return }
        
        withAnimation(.easeInOut) {
            currentIndex -= 1
            // Load previous answer if exists
            if let result = problemResults.first(where: { $0.problemId == currentProblem?.id }) {
                studentAnswer = result.studentAnswer
                showFeedback = true
                isCorrect = result.isCorrect
            } else {
                resetProblemState()
            }
        }
    }
    
    /// Skip the current problem
    func skipProblem() {
        guard config.allowSkip else { return }
        
        // Record as skipped
        if let problem = currentProblem {
            let result = PracticeResult(
                problemId: problem.id,
                isCorrect: false,
                hintsUsed: currentHintLevel,
                timeSpentSeconds: Int(currentProblemTimeSpent),
                studentAnswer: "[SKIPPED]"
            )
            problemResults.append(result)
            totalAttempted += 1
        }
        
        if canGoNext {
            nextProblem()
        } else {
            completeSession()
        }
    }
    
    /// Complete the practice session
    func completeSession() {
        sessionComplete = true
        
        // Save session results
        Task {
            await saveSessionResults()
        }
    }
    
    /// Retry incorrect problems
    func retryIncorrect() {
        let incorrectProblemIds = problemResults
            .filter { !$0.isCorrect }
            .map { $0.problemId }
        
        let incorrectProblems = problems.filter { incorrectProblemIds.contains($0.id) }
        
        guard !incorrectProblems.isEmpty else { return }
        
        // Reset for retry
        problems = incorrectProblems
        problemResults = []
        currentIndex = 0
        correctCount = 0
        totalAttempted = 0
        hintsUsedTotal = 0
        sessionComplete = false
        sessionStartTime = Date()
        resetProblemState()
    }
    
    // MARK: - Private Methods
    
    private func resetProblemState() {
        studentAnswer = ""
        showFeedback = false
        isCorrect = nil
        currentHintLevel = config.showHintsImmediately ? availableHints.count : 0
        currentProblemStartTime = Date()
    }
    
    private func normalizeAnswer(_ answer: String) -> String {
        var normalized = answer
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        
        // Remove common formatting
        normalized = normalized.replacingOccurrences(of: " ", with: "")
        normalized = normalized.replacingOccurrences(of: "$", with: "")
        normalized = normalized.replacingOccurrences(of: "\\", with: "")
        
        // Handle fraction formats
        // "1/2" should match "0.5" should match "½"
        if let fractionMatch = parseFraction(normalized) {
            normalized = String(format: "%.4f", fractionMatch)
        }
        
        return normalized
    }
    
    private func parseFraction(_ str: String) -> Double? {
        // Handle "a/b" format
        let parts = str.split(separator: "/")
        if parts.count == 2,
           let num = Double(parts[0]),
           let den = Double(parts[1]),
           den != 0 {
            return num / den
        }
        return Double(str)
    }
    
    private func updateProblemStats(problem: PracticeProblem, wasCorrect: Bool) async {
        do {
            var updated = problem
            updated.timesUsed += 1
            
            // Update average score
            let currentAvg = updated.averageScore ?? 0
            let currentCount = Double(updated.timesUsed - 1)
            let newScore = wasCorrect ? 1.0 : 0.0
            updated.averageScore = (currentAvg * currentCount + newScore) / Double(updated.timesUsed)
            
            try await Amplify.DataStore.save(updated)
        } catch {
            print("⚠️ Failed to update problem stats: \(error)")
        }
    }
    
    /// Update assignment progress (partial completion)
    private func updateAssignmentProgress() async {
        guard let assignment = assignment else { return }
        
        do {
            let updatedAssignment = try await PracticeAssignmentService.shared.updateProgress(
                assignment,
                correctCount: correctCount,
                totalAttempted: totalAttempted,
                timeSpentSeconds: Int(totalTimeSpent)
            )
            self.assignment = updatedAssignment
        } catch {
            print("⚠️ Failed to update assignment progress: \(error)")
        }
    }
    
    private func saveSessionResults() async {
        // Determine student ID
        let studentId: String
        if let childId = child?.userId {
            studentId = childId
        } else if let assignmentStudentId = assignment?.studentId {
            studentId = assignmentStudentId
        } else {
            print("⚠️ No student ID available for saving results")
            return
        }
        
        do {
            let trackingService = PracticeTrackingService.shared
            
            if let assignment = assignment {
                // Save with assignment tracking (updates assignment, mastery, curriculum progress, analytics)
                let completed = try await trackingService.recordPracticeSessionWithAssignment(
                    assignment: assignment,
                    problems: problems,
                    results: problemResults,
                    timeSpentSeconds: Int(totalTimeSpent)
                )
                
                completedAssignment = completed
                onAssignmentComplete?(completed)
                
                print("✅ Practice session with assignment completed")
                print("   Assignment: \(completed.id)")
                print("   Score: \(completed.correctCount ?? 0)/\(completed.totalAttempted ?? 0)")
            } else {
                // Save without assignment (existing behavior)
                try await trackingService.recordPracticeSession(
                    problems: problems,
                    results: problemResults,
                    studentId: studentId,
                    classroomId: nil
                )
                print("✅ Practice session results saved")
            }
        } catch {
            print("⚠️ Failed to save session results: \(error)")
        }
    }
}

// MARK: - Practice Result

struct PracticeResult: Identifiable {
    let id = UUID()
    let problemId: String
    let isCorrect: Bool
    let hintsUsed: Int
    let timeSpentSeconds: Int
    let studentAnswer: String
}

// MARK: - Session Statistics

struct PracticeSessionStats {
    let totalProblems: Int
    let attempted: Int
    let correct: Int
    let accuracy: Double
    let totalTimeSeconds: Int
    let hintsUsed: Int
    let averageTimePerProblem: Double
    
    var scoreEmoji: String {
        if accuracy >= 90 { return "🌟" }
        if accuracy >= 80 { return "⭐" }
        if accuracy >= 70 { return "👍" }
        if accuracy >= 60 { return "💪" }
        return "📚"
    }
    
    var encouragement: String {
        if accuracy >= 90 { return "Excellent work! You've mastered this!" }
        if accuracy >= 80 { return "Great job! Keep up the good work!" }
        if accuracy >= 70 { return "Good progress! A little more practice will help." }
        if accuracy >= 60 { return "Nice effort! Let's work on strengthening these skills." }
        return "Keep practicing! Every problem helps you learn."
    }
}

extension PracticeSessionViewModel {
    var sessionStats: PracticeSessionStats {
        PracticeSessionStats(
            totalProblems: problems.count,
            attempted: totalAttempted,
            correct: correctCount,
            accuracy: accuracy,
            totalTimeSeconds: Int(totalTimeSpent),
            hintsUsed: hintsUsedTotal,
            averageTimePerProblem: totalAttempted > 0 ? totalTimeSpent / Double(totalAttempted) : 0
        )
    }
}
