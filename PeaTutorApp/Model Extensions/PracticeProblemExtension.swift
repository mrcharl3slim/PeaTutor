//
//  PracticeProblem+Curriculum.swift
//  PeaTutorApp
//
//  Sprint 8 Phase 2: Enhanced PracticeProblem with Curriculum Alignment
//  Extends PracticeProblem to ensure grade-appropriate problem generation
//

import Foundation
import Amplify

// MARK: - Curriculum-Enhanced PracticeProblem Extensions

extension PracticeProblem {
    
    // MARK: - Curriculum Status
    
    /// Check if this problem has curriculum alignment
    public var hasCurriculumAlignment: Bool {
        return curriculumCode != nil && !curriculumCode!.isEmpty
    }
    
    /// Check if problem respects the student's grade boundary
    public var isGradeAppropriate: Bool {
        return respectsGradeBoundary ?? true
    }
    
    /// Get grade level number from code (e.g., 2 from "P2")
    public var gradeNumber: Int? {
        guard let code = curriculumGradeLevelCode else { return nil }
        return Int(code.dropFirst()) // Remove "P" prefix
    }
    
    // MARK: - Curriculum Display Helpers
    
    /// Formatted curriculum alignment for display
    public var curriculumAlignmentText: String? {
        guard hasCurriculumAlignment else { return nil }
        
        var parts: [String] = []
        
        if let grade = curriculumGradeLevel {
            parts.append(grade)
        }
        
        if let strand = curriculumStrand {
            parts.append(strand)
        }
        
        if let subStrand = curriculumSubStrand {
            parts.append(subStrand)
        }
        
        return parts.isEmpty ? nil : parts.joined(separator: " • ")
    }
    
    /// Grade level badge text
    public var gradeLevelBadge: String? {
        return curriculumGradeLevelCode
    }
    
    /// Curriculum strand emoji
    public var strandEmoji: String {
        guard let strand = curriculumStrand else { return "📚" }
        
        switch strand {
        case "Number and Algebra":
            return "🔢"
        case "Measurement and Geometry":
            return "📐"
        case "Statistics":
            return "📊"
        default:
            return "📚"
        }
    }
    
    /// Check if problem matches specific curriculum code
    public func matchesCurriculumCode(_ code: String) -> Bool {
        if curriculumCode == code {
            return true
        }
        return targetCurriculumCodes?.contains(code) ?? false
    }
    
    /// Check if problem is within a grade range
    public func isWithinGradeRange(min: Int, max: Int) -> Bool {
        guard let grade = gradeNumber else { return true }
        return grade >= min && grade <= max
    }
}

// MARK: - Curriculum-Enhanced Factory Methods

extension PracticeProblem {
    
    /// Create a practice problem with curriculum alignment
    public static func createWithCurriculum(
        sourceWorksheetId: String,
        sourceQuestionId: String? = nil,
        userId: String,
        problemText: String,
        answer: String,
        stepByStep: String? = nil,
        hints: [String?]? = nil,
        concept: String,
        difficultyLevel: String,
        questionType: String,
        generatedFrom: String,
        difficultyAdjustment: String? = nil,
        // Curriculum parameters
        curriculumCode: String?,
        curriculumGradeLevel: String?,
        curriculumGradeLevelCode: String?,
        curriculumStrand: String?,
        curriculumSubStrand: String?,
        respectsGradeBoundary: Bool = true,
        targetCurriculumCodes: [String]? = nil,
        // AI metadata
        aiModel: String,
        tokensUsed: Int? = nil
    ) -> PracticeProblem {
        return PracticeProblem(
            sourceWorksheetId: sourceWorksheetId,
            sourceQuestionId: sourceQuestionId,
            userId: userId,
            problemText: problemText,
            answer: answer,
            stepByStep: stepByStep,
            hints: hints,
            concept: concept,
            difficultyLevel: difficultyLevel,
            questionType: questionType,
            generatedFrom: generatedFrom,
            difficultyAdjustment: difficultyAdjustment,
            timesUsed: 0,
            averageScore: nil,
            // Curriculum fields
            curriculumCode: curriculumCode,
            curriculumGradeLevel: curriculumGradeLevel,
            curriculumGradeLevelCode: curriculumGradeLevelCode,
            curriculumStrand: curriculumStrand,
            curriculumSubStrand: curriculumSubStrand,
            respectsGradeBoundary: respectsGradeBoundary,
            targetCurriculumCodes: targetCurriculumCodes,
            // Metadata
            generatedAt: .now(),
            aiModel: aiModel,
            tokensUsed: tokensUsed
        )
    }
    
    /// Update problem with curriculum alignment (returns new instance)
    public func withCurriculumAlignment(
        curriculumCode: String?,
        gradeLevel: String?,
        gradeLevelCode: String?,
        strand: String?,
        subStrand: String?,
        respectsGradeBoundary: Bool = true,
        targetCodes: [String]? = nil
    ) -> PracticeProblem {
        var updated = self
        updated.curriculumCode = curriculumCode
        updated.curriculumGradeLevel = gradeLevel
        updated.curriculumGradeLevelCode = gradeLevelCode
        updated.curriculumStrand = strand
        updated.curriculumSubStrand = subStrand
        updated.respectsGradeBoundary = respectsGradeBoundary
        updated.targetCurriculumCodes = targetCodes
        return updated
    }
}

// MARK: - Array Extensions for Curriculum Filtering

extension Array where Element == PracticeProblem {
    
    /// Filter problems with curriculum alignment
    public func withCurriculumAlignment() -> [PracticeProblem] {
        return filter { $0.hasCurriculumAlignment }
    }
    
    /// Filter by grade level code (e.g., "P2")
    public func forGradeCode(_ code: String) -> [PracticeProblem] {
        return filter { $0.curriculumGradeLevelCode == code }
    }
    
    /// Filter by grade level (e.g., "Primary 2")
    public func forGradeLevel(_ level: String) -> [PracticeProblem] {
        return filter { $0.curriculumGradeLevel == level }
    }
    
    /// Filter by strand
    public func forStrand(_ strand: String) -> [PracticeProblem] {
        return filter { $0.curriculumStrand == strand }
    }
    
    /// Filter by sub-strand
    public func forSubStrand(_ subStrand: String) -> [PracticeProblem] {
        return filter { $0.curriculumSubStrand == subStrand }
    }
    
    /// Filter by curriculum code
    public func forCurriculumCode(_ code: String) -> [PracticeProblem] {
        return filter { $0.matchesCurriculumCode(code) }
    }
    
    /// Filter grade-appropriate problems only
    public func gradeAppropriateOnly() -> [PracticeProblem] {
        return filter { $0.isGradeAppropriate }
    }
    
    /// Filter problems within grade range
    public func withinGradeRange(min: Int, max: Int) -> [PracticeProblem] {
        return filter { $0.isWithinGradeRange(min: min, max: max) }
    }
    
    /// Filter problems at or below a specific grade
    public func atOrBelowGrade(_ maxGrade: Int) -> [PracticeProblem] {
        return filter { problem in
            guard let grade = problem.gradeNumber else { return true }
            return grade <= maxGrade
        }
    }
    
    /// Filter problems targeting specific curriculum codes
    public func targetingCurriculumCodes(_ codes: [String]) -> [PracticeProblem] {
        let codesSet = Set(codes)
        return filter { problem in
            if let targetCodes = problem.targetCurriculumCodes {
                return !Set(targetCodes).isDisjoint(with: codesSet)
            }
            if let code = problem.curriculumCode {
                return codesSet.contains(code)
            }
            return false
        }
    }
    
    /// Group by grade level code
    public func groupedByGradeCode() -> [String: [PracticeProblem]] {
        var grouped: [String: [PracticeProblem]] = [:]
        
        for problem in self {
            let grade = problem.curriculumGradeLevelCode ?? "Unknown"
            grouped[grade, default: []].append(problem)
        }
        
        return grouped
    }
    
    /// Group by curriculum strand
    public func groupedByStrand() -> [String: [PracticeProblem]] {
        var grouped: [String: [PracticeProblem]] = [:]
        
        for problem in self {
            let strand = problem.curriculumStrand ?? "Unknown"
            grouped[strand, default: []].append(problem)
        }
        
        return grouped
    }
    
    /// Group by concept
    public func groupedByConcept() -> [String: [PracticeProblem]] {
        return Dictionary(grouping: self) { $0.concept }
    }
    
    /// Get all unique curriculum codes
    public func allCurriculumCodes() -> [String] {
        var codes = Set<String>()
        
        for problem in self {
            if let code = problem.curriculumCode {
                codes.insert(code)
            }
            if let targetCodes = problem.targetCurriculumCodes {
                codes.formUnion(targetCodes.compactMap { $0 })
            }
        }
        
        return codes.sorted()
    }
    
    /// Get all unique grade levels
    public func allGradeLevels() -> [String] {
        return compactMap { $0.curriculumGradeLevel }
            .unique()
            .sorted()
    }
    
    /// Count problems by grade
    public func countByGrade() -> [String: Int] {
        var counts: [String: Int] = [:]
        
        for problem in self {
            let grade = problem.curriculumGradeLevelCode ?? "Unknown"
            counts[grade, default: 0] += 1
        }
        
        return counts
    }
}

// MARK: - Grade Boundary Validation

extension PracticeProblem {
    
    /// Validate that a problem is appropriate for a student's grade
    public static func validateGradeBoundary(
        problemGradeCode: String?,
        studentGradeCode: String?,
        allowHigherGrades: Bool = false
    ) -> Bool {
        guard let problemCode = problemGradeCode,
              let studentCode = studentGradeCode,
              let problemGrade = Int(problemCode.dropFirst()),
              let studentGrade = Int(studentCode.dropFirst()) else {
            return true // If we can't determine, allow it
        }
        
        if allowHigherGrades {
            // Allow problems up to 1 grade above student's level
            return problemGrade <= studentGrade + 1
        } else {
            // Strict boundary: problem must be at or below student's grade
            return problemGrade <= studentGrade
        }
    }
}

// MARK: - Note: Schema Property Placeholders

// The following properties need to be added to the base PracticeProblem model
// These are placeholders showing what fields are expected after schema update

/*
 After running `amplify codegen models` with the updated schema,
 the PracticeProblem model should have these additional properties:
 
 public var curriculumCode: String?
 public var curriculumGradeLevel: String?
 public var curriculumGradeLevelCode: String?
 public var curriculumStrand: String?
 public var curriculumSubStrand: String?
 public var respectsGradeBoundary: Bool?
 public var targetCurriculumCodes: [String?]?
 */
