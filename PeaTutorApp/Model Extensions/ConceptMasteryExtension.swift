//
//  ConceptMastery+Extensions.swift
//  PeaTutorApp
//
//  Sprint 7.1: Deep Worksheet Analytics Engine
//  Extensions for ConceptMastery model (adds helper methods to Amplify-generated base)
//
//  ⚠️ IMPORTANT: This file extends the Amplify-generated ConceptMastery.swift
//  Do NOT modify the base ConceptMastery.swift file - add extensions here instead
//

import Foundation
import Amplify

// MARK: - Mastery Level Classification

extension ConceptMastery {
    /// Get mastery level classification based on percentage
    public var masteryLevel: MasteryLevel {
        switch masteryPercentage {
        case 80...100:
            return .mastered
        case 60..<80:
            return .developing
        case 40..<60:
            return .emerging
        default:
            return .needsWork
        }
    }
    
    /// Get trend direction as enum
    public var trendDirection: TrendDirection {
        switch trend.lowercased() {
        case "improving":
            return .up
        case "declining":
            return .down
        default:
            return .stable
        }
    }
    
    /// Get performance by difficulty level
    public func performanceByDifficulty(_ difficulty: QuestionDifficulty) -> (attempted: Int, correct: Int, percentage: Double) {
        let (attempted, correct): (Int, Int)
        
        switch difficulty {
        case .easy:
            attempted = easyQuestions
            correct = easyCorrect
        case .medium:
            attempted = mediumQuestions
            correct = mediumCorrect
        case .hard:
            attempted = hardQuestions
            correct = hardCorrect
        }
        
        let percentage = attempted > 0 ? (Double(correct) / Double(attempted)) * 100 : 0.0
        return (attempted, correct, percentage)
    }
}

// MARK: - Calculation Helpers

extension ConceptMastery {
    /// Record a new attempt and update mastery metrics
    /// This returns a NEW ConceptMastery instance (required for DataStore)
    public func recordingAttempt(isCorrect: Bool, difficulty: QuestionDifficulty) -> ConceptMastery {
        var updated = self
        
        // Update totals
        updated.totalAttempts += 1
        if isCorrect {
            updated.correctAttempts += 1
        } else {
            updated.incorrectAttempts += 1
        }
        
        // Update difficulty-specific counts
        switch difficulty {
        case .easy:
            updated.easyQuestions += 1
            if isCorrect { updated.easyCorrect += 1 }
        case .medium:
            updated.mediumQuestions += 1
            if isCorrect { updated.mediumCorrect += 1 }
        case .hard:
            updated.hardQuestions += 1
            if isCorrect { updated.hardCorrect += 1 }
        }
        
        // Recalculate metrics
        updated.accuracyRate = updated.totalAttempts > 0 ?
            (Double(updated.correctAttempts) / Double(updated.totalAttempts)) * 100 : 0.0
        
        // Update mastery percentage (weighted by difficulty)
        updated.masteryPercentage = updated.calculateWeightedMastery()
        
        // Update timestamp
        updated.lastPracticed = Temporal.DateTime.now()
        updated.lastUpdatedAt = Temporal.DateTime.now()
        
        return updated
    }
    
    /// Calculate weighted mastery based on difficulty
    private func calculateWeightedMastery() -> Double {
        var weightedScore = 0.0
        var totalWeight = 0.0
        
        // Easy questions: weight 1.0
        if easyQuestions > 0 {
            let easyRate = Double(easyCorrect) / Double(easyQuestions)
            weightedScore += easyRate * Double(easyQuestions) * 1.0
            totalWeight += Double(easyQuestions) * 1.0
        }
        
        // Medium questions: weight 1.5
        if mediumQuestions > 0 {
            let mediumRate = Double(mediumCorrect) / Double(mediumQuestions)
            weightedScore += mediumRate * Double(mediumQuestions) * 1.5
            totalWeight += Double(mediumQuestions) * 1.5
        }
        
        // Hard questions: weight 2.0
        if hardQuestions > 0 {
            let hardRate = Double(hardCorrect) / Double(hardQuestions)
            weightedScore += hardRate * Double(hardQuestions) * 2.0
            totalWeight += Double(hardQuestions) * 2.0
        }
        
        return totalWeight > 0 ? (weightedScore / totalWeight) * 100 : 0.0
    }
    
    /// Mark this concept as resolved (returns new instance)
    public func markingAsResolved() -> ConceptMastery {
        var updated = self
        updated.lastUpdatedAt = Temporal.DateTime.now()
        return updated
    }
}

// MARK: - Display Helpers

extension ConceptMastery {
    /// Formatted mastery percentage for display
    public var masteryPercentageFormatted: String {
        return "\(Int(masteryPercentage))%"
    }
    
    /// Formatted accuracy rate for display
    public var accuracyRateFormatted: String {
        return "\(Int(accuracyRate))%"
    }
    
    /// Human-readable last practiced
    public var lastPracticedFormatted: String {
        guard let lastPracticed = lastPracticed else {
            return "Never"
        }
        
        let date = lastPracticed.foundationDate
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .hour], from: date, to: now)
        
        if let days = components.day, days > 0 {
            return "\(days) day\(days == 1 ? "" : "s") ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            return "Just now"
        }
    }
}

// MARK: - Supporting Enums

public enum MasteryLevel: String, CaseIterable {
    case mastered = "Mastered"          // 80-100%
    case developing = "Developing"      // 60-79%
    case emerging = "Emerging"          // 40-59%
    case needsWork = "Needs Work"       // 0-39%
    
    public var color: String {
        switch self {
        case .mastered: return "green"
        case .developing: return "yellow"
        case .emerging: return "orange"
        case .needsWork: return "red"
        }
    }
    
    public var icon: String {
        switch self {
        case .mastered: return "checkmark.circle.fill"
        case .developing: return "chart.line.uptrend.xyaxis"
        case .emerging: return "arrow.up.circle"
        case .needsWork: return "exclamationmark.triangle.fill"
        }
    }
    
    public var description: String {
        switch self {
        case .mastered:
            return "Excellent understanding - ready for advanced problems"
        case .developing:
            return "Good progress - continue practicing"
        case .emerging:
            return "Building understanding - needs more practice"
        case .needsWork:
            return "Struggling - needs focused intervention"
        }
    }
}

public enum TrendDirection: String, CaseIterable {
    case up = "improving"
    case stable = "stable"
    case down = "declining"
    
    public var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .down: return "arrow.down.right"
        }
    }
    
    public var color: String {
        switch self {
        case .up: return "green"
        case .stable: return "gray"
        case .down: return "red"
        }
    }
    
    public var description: String {
        switch self {
        case .up: return "Performance is improving"
        case .stable: return "Performance is stable"
        case .down: return "Performance is declining"
        }
    }
}

public enum QuestionDifficulty: String, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    
    public var weight: Double {
        switch self {
        case .easy: return 1.0
        case .medium: return 1.5
        case .hard: return 2.0
        }
    }
}

// MARK: - Convenience Initializers

extension ConceptMastery {
    /// Create a new concept mastery record with defaults
    public static func createNew(
        studentId: String,
        classroomId: String? = nil,
        concept: String,
        gradeLevel: String? = nil
    ) -> ConceptMastery {
        return ConceptMastery(
            studentId: studentId,
            classroomId: classroomId,
            concept: concept,
            gradeLevel: gradeLevel,
            masteryPercentage: 0.0,
            accuracyRate: 0.0,
            totalAttempts: 0,
            correctAttempts: 0,
            incorrectAttempts: 0,
            trend: "stable",
            recentQuestions: 0,
            lastPracticed: nil,
            easyQuestions: 0,
            mediumQuestions: 0,
            hardQuestions: 0,
            easyCorrect: 0,
            mediumCorrect: 0,
            hardCorrect: 0,
            strengthAreas: nil,
            improvementAreas: nil,
            recommendedPractice: nil,
            calculatedAt: Temporal.DateTime.now(),
            lastUpdatedAt: Temporal.DateTime.now()
        )
    }
}


extension ConceptMastery {
    
    // MARK: - Curriculum Status
    
    /// Check if this concept is aligned to curriculum
    public var hasCurriculumAlignment: Bool {
        return curriculumCode != nil && !curriculumCode!.isEmpty
    }
    
    /// Parse grade level from curriculum code (e.g., "P2" from "P2-NA-MD-3.1")
    public var curriculumGradeLevelCode: String? {
        guard let code = curriculumCode else { return nil }
        let components = code.split(separator: "-")
        return components.first.map(String.init)
    }
    
    /// Get full grade level from code (e.g., "Primary 2" from "P2")
    public var curriculumGradeLevel: String? {
        get async {
            guard let code = curriculumGradeLevelCode else { return nil }
            return await CurriculumService.codeToGradeLevel(code)
        }
    }
    
    /// Check if student has mastered all prerequisites for this concept
    public var hasPrerequisiteGaps: Bool {
        guard let gaps = prerequisiteGaps else { return false }
        return !gaps.isEmpty
    }
    
    /// Number of prerequisite gaps
    public var prerequisiteGapCount: Int {
        return prerequisiteGaps?.count ?? 0
    }
    
    // MARK: - Curriculum Progress Status
    
    /// Get curriculum progress status combining mastery and prerequisites
    public var curriculumProgressStatus: CurriculumProgressStatus {
        // First check prerequisites
        if hasPrerequisiteGaps {
            return .prerequisitesNeeded
        }
        
        // Then check mastery level
        switch masteryPercentage {
        case 80...100:
            return .mastered
        case 60..<80:
            return .developing
        case 40..<60:
            return .emerging
        default:
            return .notStarted
        }
    }
    
    // MARK: - Display Helpers
    
    /// Formatted curriculum code for display
    public var curriculumCodeFormatted: String {
        guard let code = curriculumCode else {
            return "Not aligned"
        }
        return code
    }
    
    /// Full curriculum description combining strand, sub-strand, and topic
    public var curriculumDescription: String? {
        guard hasCurriculumAlignment else { return nil }
        
        var parts: [String] = []
        
        if let strand = curriculumStrand {
            parts.append(strand)
        }
        
        if let subStrand = curriculumSubStrand {
            parts.append(subStrand)
        }
        
        if let topic = curriculumTopicTitle {
            parts.append(topic)
        }
        
        return parts.isEmpty ? nil : parts.joined(separator: " › ")
    }
    
    /// Prerequisite status message
    public var prerequisiteStatusMessage: String {
        guard let gaps = prerequisiteGaps, !gaps.isEmpty else {
            return "All prerequisites mastered ✓"
        }
        
        if gaps.count == 1 {
            return "1 prerequisite needs work"
        }
        return "\(gaps.count) prerequisites need work"
    }
    
    /// Curriculum alignment badge text
    public var curriculumBadgeText: String? {
        guard let code = curriculumGradeLevelCode else { return nil }
        return code // e.g., "P2"
    }
}

// MARK: - Curriculum Progress Status Enum

public enum CurriculumProgressStatus: String, CaseIterable {
    case mastered = "Mastered"
    case developing = "Developing"
    case emerging = "Emerging"
    case notStarted = "Not Started"
    case prerequisitesNeeded = "Prerequisites Needed"
    
    public var icon: String {
        switch self {
        case .mastered: return "checkmark.seal.fill"
        case .developing: return "chart.line.uptrend.xyaxis"
        case .emerging: return "leaf.fill"
        case .notStarted: return "circle.dashed"
        case .prerequisitesNeeded: return "exclamationmark.triangle.fill"
        }
    }
    
    public var color: String {
        switch self {
        case .mastered: return "green"
        case .developing: return "blue"
        case .emerging: return "yellow"
        case .notStarted: return "gray"
        case .prerequisitesNeeded: return "orange"
        }
    }
    
    public var description: String {
        switch self {
        case .mastered:
            return "Student has demonstrated strong understanding"
        case .developing:
            return "Student is making good progress"
        case .emerging:
            return "Student is building foundational understanding"
        case .notStarted:
            return "Student hasn't attempted this concept yet"
        case .prerequisitesNeeded:
            return "Student needs to master prerequisite concepts first"
        }
    }
    
    public var priority: Int {
        switch self {
        case .prerequisitesNeeded: return 0
        case .notStarted: return 1
        case .emerging: return 2
        case .developing: return 3
        case .mastered: return 4
        }
    }
}

// MARK: - Curriculum-Enhanced Factory Methods

extension ConceptMastery {
    
    /// Create a new concept mastery record with curriculum alignment
    public static func createNewWithCurriculum(
        studentId: String,
        classroomId: String? = nil,
        concept: String,
        gradeLevel: String? = nil,
        curriculumCode: String,
        curriculumStrand: String? = nil,
        curriculumSubStrand: String? = nil,
        curriculumTopicTitle: String? = nil
    ) -> ConceptMastery {
        return ConceptMastery(
            studentId: studentId,
            classroomId: classroomId,
            concept: concept,
            gradeLevel: gradeLevel,
            masteryPercentage: 0.0,
            accuracyRate: 0.0,
            totalAttempts: 0,
            correctAttempts: 0,
            incorrectAttempts: 0,
            trend: "stable",
            recentQuestions: 0,
            lastPracticed: nil,
            easyQuestions: 0,
            mediumQuestions: 0,
            hardQuestions: 0,
            easyCorrect: 0,
            mediumCorrect: 0,
            hardCorrect: 0,
            strengthAreas: nil,
            improvementAreas: nil,
            recommendedPractice: nil,
            // Curriculum fields
            curriculumCode: curriculumCode,
            curriculumStrand: curriculumStrand,
            curriculumSubStrand: curriculumSubStrand,
            curriculumTopicTitle: curriculumTopicTitle,
            prerequisitesMastered: nil,
            prerequisiteGaps: nil,
            curriculumMappedAt: .now(),
            // Timestamps
            calculatedAt: Temporal.DateTime.now(),
            lastUpdatedAt: Temporal.DateTime.now()
        )
    }
    
    /// Update existing mastery with curriculum alignment (returns new instance)
    public func withCurriculumAlignment(
        curriculumCode: String,
        strand: String?,
        subStrand: String?,
        topicTitle: String?,
        prerequisitesMastered: Bool?,
        prerequisiteGaps: [String]?
    ) -> ConceptMastery {
        var updated = self
        updated.curriculumCode = curriculumCode
        updated.curriculumStrand = strand
        updated.curriculumSubStrand = subStrand
        updated.curriculumTopicTitle = topicTitle
        updated.prerequisitesMastered = prerequisitesMastered
        updated.prerequisiteGaps = prerequisiteGaps
        updated.curriculumMappedAt = .now()
        updated.lastUpdatedAt = .now()
        return updated
    }
    
    /// Update prerequisite status (returns new instance)
    public func withPrerequisiteStatus(
        mastered: Bool,
        gaps: [String]?
    ) -> ConceptMastery {
        var updated = self
        updated.prerequisitesMastered = mastered
        updated.prerequisiteGaps = gaps
        updated.lastUpdatedAt = .now()
        return updated
    }
}

// MARK: - Array Extensions for Curriculum Filtering

extension Array where Element == ConceptMastery {
    
    /// Filter mastery records that have curriculum alignment
    public func withCurriculumAlignment() -> [ConceptMastery] {
        return filter { $0.hasCurriculumAlignment }
    }
    
    /// Filter by curriculum grade level code (e.g., "P2")
    public func forCurriculumGradeCode(_ code: String) -> [ConceptMastery] {
        return filter { $0.curriculumGradeLevelCode == code }
    }
    
    /// Filter by curriculum strand
    public func forCurriculumStrand(_ strand: String) -> [ConceptMastery] {
        return filter { $0.curriculumStrand == strand }
    }
    
    /// Filter by curriculum sub-strand
    public func forCurriculumSubStrand(_ subStrand: String) -> [ConceptMastery] {
        return filter { $0.curriculumSubStrand == subStrand }
    }
    
    /// Filter by curriculum progress status
    public func withStatus(_ status: CurriculumProgressStatus) -> [ConceptMastery] {
        return filter { $0.curriculumProgressStatus == status }
    }
    
    /// Filter concepts with prerequisite gaps
    public func withPrerequisiteGaps() -> [ConceptMastery] {
        return filter { $0.hasPrerequisiteGaps }
    }
    
    /// Filter concepts without prerequisite gaps
    public func withoutPrerequisiteGaps() -> [ConceptMastery] {
        return filter { !$0.hasPrerequisiteGaps }
    }
    
    /// Group by curriculum grade level
    public func groupedByCurriculumGrade() -> [String: [ConceptMastery]] {
        var grouped: [String: [ConceptMastery]] = [:]
        
        for mastery in self {
            let grade = mastery.curriculumGradeLevelCode ?? "Unknown"
            grouped[grade, default: []].append(mastery)
        }
        
        return grouped
    }
    
    /// Group by curriculum strand
    public func groupedByCurriculumStrand() -> [String: [ConceptMastery]] {
        var grouped: [String: [ConceptMastery]] = [:]
        
        for mastery in self {
            let strand = mastery.curriculumStrand ?? "Unknown"
            grouped[strand, default: []].append(mastery)
        }
        
        return grouped
    }
    
    /// Group by curriculum progress status
    public func groupedByProgressStatus() -> [CurriculumProgressStatus: [ConceptMastery]] {
        return Dictionary(grouping: self) { $0.curriculumProgressStatus }
    }
    
    /// Sort by curriculum progress (prerequisites first, then by mastery)
    public func sortedByCurriculumPriority() -> [ConceptMastery] {
        return sorted { lhs, rhs in
            // First by progress status priority
            if lhs.curriculumProgressStatus.priority != rhs.curriculumProgressStatus.priority {
                return lhs.curriculumProgressStatus.priority < rhs.curriculumProgressStatus.priority
            }
            // Then by mastery percentage (lower first for focus areas)
            return lhs.masteryPercentage < rhs.masteryPercentage
        }
    }
    
    /// Get all unique curriculum codes
    public func allCurriculumCodes() -> [String] {
        return compactMap { $0.curriculumCode }.unique().sorted()
    }
    
    /// Get all prerequisite gaps across all concepts
    public func allPrerequisiteGaps() -> [String] {
        var gaps = Set<String>()
        
        for mastery in self {
            if let masteryGaps = mastery.prerequisiteGaps {
                gaps.formUnion(masteryGaps.compactMap { $0 })
            }
        }
        
        return gaps.sorted()
    }
    
    /// Calculate curriculum coverage percentage
    public func curriculumCoveragePercentage(totalStandards: Int) -> Double {
        guard totalStandards > 0 else { return 0 }
        let alignedCount = withCurriculumAlignment().count
        return (Double(alignedCount) / Double(totalStandards)) * 100
    }
    
    /// Calculate curriculum mastery percentage (% of aligned concepts mastered)
    public func curriculumMasteryPercentage() -> Double {
        let aligned = withCurriculumAlignment()
        guard !aligned.isEmpty else { return 0 }
        
        let mastered = aligned.filter { $0.masteryPercentage >= 80 }.count
        return (Double(mastered) / Double(aligned.count)) * 100
    }
}

// MARK: - Sequence Extension for Unique

extension Sequence where Element: Hashable {
    func unique() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

// MARK: - Note: Schema Property Placeholders

// The following properties need to be added to the base ConceptMastery model
// These are placeholders showing what fields are expected after schema update

/*
 After running `amplify codegen models` with the updated schema,
 the ConceptMastery model should have these additional properties:
 
 public var curriculumCode: String?
 public var curriculumStrand: String?
 public var curriculumSubStrand: String?
 public var curriculumTopicTitle: String?
 public var prerequisitesMastered: Bool?
 public var prerequisiteGaps: [String?]?
 public var curriculumMappedAt: Temporal.DateTime?
 */

