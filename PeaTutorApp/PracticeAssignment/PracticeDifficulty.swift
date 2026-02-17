//
//  PracticeDifficulty.swift
//  PeaTutorApp
//
//  Sprint 7.4: AI-Powered Practice Generation
//  Defines difficulty levels for practice problems
//

import Foundation
import SwiftUI

/// Difficulty levels for generated practice problems
enum PracticeDifficulty: String, CaseIterable, Identifiable, Codable {
    case easier = "easier"
    case similar = "similar"
    case harder = "harder"
    
    var id: String { rawValue }
    
    // MARK: - Display Properties
    
    var displayName: String {
        switch self {
        case .easier: return "Easier"
        case .similar: return "Similar"
        case .harder: return "Harder"
        }
    }
    
    var description: String {
        switch self {
        case .easier: return "Build confidence with simpler problems"
        case .similar: return "Practice at the same difficulty level"
        case .harder: return "Challenge yourself with advanced problems"
        }
    }
    
    var shortDescription: String {
        switch self {
        case .easier: return "Simpler problems"
        case .similar: return "Same level"
        case .harder: return "More challenging"
        }
    }
    
    var icon: String {
        switch self {
        case .easier: return "📘"
        case .similar: return "📗"
        case .harder: return "📕"
        }
    }
    
    var systemIcon: String {
        switch self {
        case .easier: return "arrow.down.circle.fill"
        case .similar: return "equal.circle.fill"
        case .harder: return "arrow.up.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .easier: return .blue
        case .similar: return .green
        case .harder: return .orange
        }
    }
    
    // MARK: - Grade Level Adjustment
    
    /// How much to adjust the grade level (negative = easier grade)
    var gradeAdjustment: Int {
        switch self {
        case .easier: return -1
        case .similar: return 0
        case .harder: return 1
        }
    }
    
    /// Get adjusted grade level string
    func adjustedGradeLevel(from baseGrade: String) -> String {
        // Parse grade from string like "Grade 4" or "Grade 5"
        let gradeNumber = extractGradeNumber(from: baseGrade)
        let adjustedGrade = max(1, min(12, gradeNumber + gradeAdjustment))
        return "Grade \(adjustedGrade)"
    }
    
    private func extractGradeNumber(from gradeString: String) -> Int {
        let numbers = gradeString.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()
        return Int(numbers) ?? 5 // Default to grade 5
    }
    
    // MARK: - Prompt Instructions
    
    /// Instructions for AI on how to adjust difficulty
    var difficultyInstructions: String {
        switch self {
        case .easier:
            return """
            Make these problems EASIER by:
            - Using smaller, simpler numbers (single digits, multiples of 5 or 10)
            - Reducing the number of steps required
            - Using clearer, more direct wording
            - Avoiding mixed operations
            - Providing more straightforward patterns
            """
        case .similar:
            return """
            Keep these problems at the SAME difficulty by:
            - Using similar number ranges and complexity
            - Maintaining the same number of steps
            - Using comparable vocabulary level
            - Keeping similar problem structures
            """
        case .harder:
            return """
            Make these problems HARDER by:
            - Using larger or more complex numbers
            - Adding additional steps or conditions
            - Combining multiple concepts
            - Using more sophisticated word problems
            - Including edge cases (negative numbers, fractions, etc.)
            """
        }
    }
    
    // MARK: - Recommendation Logic
    
    /// Recommend difficulty based on student's mastery percentage
    static func recommended(forMasteryPercentage mastery: Double) -> PracticeDifficulty {
        if mastery < 50 {
            return .easier
        } else if mastery < 75 {
            return .similar
        } else {
            return .harder
        }
    }
    
    /// Recommend difficulty based on previous session score
    static func recommended(forSessionScore score: Double) -> PracticeDifficulty {
        if score < 60 {
            return .easier
        } else if score < 85 {
            return .similar
        } else {
            return .harder
        }
    }
}

// MARK: - Practice Generation Configuration

struct PracticeGenerationConfig {
    let difficulty: PracticeDifficulty
    let problemCount: Int
    let concepts: [String]
    let gradeLevel: String
    let sourceWorksheetId: String?
    let sourceQuestionId: String?
    
    static let `default` = PracticeGenerationConfig(
        difficulty: .similar,
        problemCount: 10,
        concepts: [],
        gradeLevel: "Grade 5",
        sourceWorksheetId: nil,
        sourceQuestionId: nil
    )
    
    /// Available problem counts for user selection
    static let availableCounts = [5, 10, 15, 20]
}

// MARK: - Practice Session Configuration

struct PracticeSessionConfig {
    let showHintsImmediately: Bool
    let autoAdvance: Bool
    let showStepByStepAfterSubmit: Bool
    let allowSkip: Bool
    let timeLimit: TimeInterval? // nil means no time limit
    
    static let `default` = PracticeSessionConfig(
        showHintsImmediately: false,
        autoAdvance: false,
        showStepByStepAfterSubmit: true,
        allowSkip: true,
        timeLimit: nil
    )
    
    static let timed = PracticeSessionConfig(
        showHintsImmediately: false,
        autoAdvance: false,
        showStepByStepAfterSubmit: true,
        allowSkip: false,
        timeLimit: 30 * 60 // 30 minutes
    )
}
