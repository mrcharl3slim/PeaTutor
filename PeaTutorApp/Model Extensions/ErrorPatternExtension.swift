//
//  ErrorPattern+Extensions.swift
//  PeaTutorApp
//
//  Sprint 7.1: Deep Worksheet Analytics Engine
//  Extensions for ErrorPattern model (adds helper methods to Amplify-generated base)
//
//  ⚠️ IMPORTANT: This file extends the Amplify-generated ErrorPattern.swift
//  Do NOT modify the base ErrorPattern.swift file - add extensions here instead
//

import Foundation
import Amplify

// MARK: - Error Severity Helpers

extension ErrorPattern {
    /// Get severity as enum for easier comparison
    public var severityLevel: ErrorSeverity {
        return ErrorSeverity(rawValue: severity.lowercased()) ?? .medium
    }
    
    /// Check if error is high severity
    public var isHighSeverity: Bool {
        return severityLevel == .high
    }
    
    /// Check if error should be considered active
    public var isActive: Bool {
        guard !isResolved else { return false }
        
        // Consider inactive if not seen in 30 days
        let daysSinceLastSeen = Calendar.current.dateComponents(
            [.day],
            from: lastSeen.foundationDate,
            to: Date()
        ).day ?? 0
        
        return daysSinceLastSeen < 30
    }
}

// MARK: - Error Pattern Analysis

extension ErrorPattern {
    /// Record a new occurrence of this error (returns new instance for DataStore)
    public func recordingOccurrence(questionId: String? = nil) -> ErrorPattern {
        var updated = self
        
        // Increment count
        updated.occurrenceCount += 1
        updated.lastSeen = Temporal.DateTime.now()
        updated.lastAnalyzedAt = Temporal.DateTime.now()
        
        // Add question ID if provided
        if let questionId = questionId {
            var currentIds = updated.exampleQuestionIds?.compactMap { $0 } ?? []
            if currentIds.count < 5 && !currentIds.contains(questionId) {
                currentIds.append(questionId)
                updated.exampleQuestionIds = currentIds.map { $0 as String? }
            }
        }
        
        // Recalculate severity
        let impactsMultiple = updated.affectedConcepts.count > 1
        let newSeverity = ErrorSeverity.calculate(
            occurrences: updated.occurrenceCount,
            impactsMultipleConcepts: impactsMultiple
        )
        updated.severity = newSeverity.rawValue
        
        return updated
    }
    
    /// Mark error as resolved (returns new instance)
    public func markingAsResolved() -> ErrorPattern {
        var updated = self
        updated.isResolved = true
        updated.resolvedAt = Temporal.DateTime.now()
        updated.lastAnalyzedAt = Temporal.DateTime.now()
        return updated
    }
    
    /// Days since last occurrence
    public var daysSinceLastSeen: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.day],
            from: lastSeen.foundationDate,
            to: Date()
        )
        return components.day ?? 0
    }
    
    /// Days since first detected
    public var daysSinceDetected: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.day],
            from: firstSeen.foundationDate,
            to: Date()
        )
        return components.day ?? 0
    }
}

// MARK: - Display Helpers

extension ErrorPattern {
    /// Formatted occurrence count for display
    public var occurrenceCountFormatted: String {
        return "\(occurrenceCount) time\(occurrenceCount == 1 ? "" : "s")"
    }
    
    /// Status badge text
    public var statusText: String {
        if isResolved {
            return "Resolved"
        } else if isActive {
            return "Active"
        } else {
            return "Inactive"
        }
    }
    
    /// Status badge color
    public var statusColor: String {
        if isResolved {
            return "green"
        } else if isActive && isHighSeverity {
            return "red"
        } else if isActive {
            return "orange"
        } else {
            return "gray"
        }
    }
    
    /// Human-readable last seen
    public var lastSeenFormatted: String {
        let days = daysSinceLastSeen
        
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Yesterday"
        } else if days < 7 {
            return "\(days) days ago"
        } else if days < 30 {
            let weeks = days / 7
            return "\(weeks) week\(weeks == 1 ? "" : "s") ago"
        } else {
            let months = days / 30
            return "\(months) month\(months == 1 ? "" : "s") ago"
        }
    }
}

// MARK: - Error Type Classification

extension ErrorPattern {
    /// Common error types in mathematics
    public enum CommonErrorType: String, CaseIterable {
        case carelessMistake = "Careless Mistake"
        case conceptualError = "Conceptual Error"
        case proceduralError = "Procedural Error"
        case computationError = "Computation Error"
        case signError = "Sign Error"
        case orderOfOperations = "Order of Operations"
        case multiStepError = "Multi-step Problem Error"
        case wordProblemMisinterpretation = "Word Problem Misinterpretation"
        
        public var description: String {
            switch self {
            case .carelessMistake:
                return "Simple arithmetic mistakes or copying errors"
            case .conceptualError:
                return "Fundamental misunderstanding of mathematical concepts"
            case .proceduralError:
                return "Incorrect application of algorithms or procedures"
            case .computationError:
                return "Errors in basic arithmetic operations"
            case .signError:
                return "Mistakes with positive/negative signs"
            case .orderOfOperations:
                return "Incorrect sequence in multi-operation problems"
            case .multiStepError:
                return "Errors in problems requiring multiple steps"
            case .wordProblemMisinterpretation:
                return "Misreading or misunderstanding word problems"
            }
        }
        
        public var icon: String {
            switch self {
            case .carelessMistake: return "exclamationmark.circle"
            case .conceptualError: return "lightbulb.slash"
            case .proceduralError: return "list.bullet.clipboard"
            case .computationError: return "plus.forwardslash.minus"
            case .signError: return "plus.slash.minus"
            case .orderOfOperations: return "arrow.up.arrow.down"
            case .multiStepError: return "stairs"
            case .wordProblemMisinterpretation: return "text.book.closed"
            }
        }
    }
    
    /// Common error categories
    public enum ErrorCategory: String, CaseIterable {
        case computation = "Computation"
        case fractions = "Fractions"
        case decimals = "Decimals"
        case algebra = "Algebra"
        case geometry = "Geometry"
        case wordProblems = "Word Problems"
        case measurement = "Measurement"
        case dataAnalysis = "Data Analysis"
        
        public var icon: String {
            switch self {
            case .computation: return "plus.slash.minus"
            case .fractions: return "divide"
            case .decimals: return "point.3.connected.trianglepath.dotted"
            case .algebra: return "x.squareroot"
            case .geometry: return "triangle"
            case .wordProblems: return "text.book.closed"
            case .measurement: return "ruler"
            case .dataAnalysis: return "chart.bar"
            }
        }
        
        public var color: String {
            switch self {
            case .computation: return "blue"
            case .fractions: return "orange"
            case .decimals: return "purple"
            case .algebra: return "red"
            case .geometry: return "green"
            case .wordProblems: return "brown"
            case .measurement: return "cyan"
            case .dataAnalysis: return "indigo"
            }
        }
    }
}

// MARK: - Error Severity

public enum ErrorSeverity: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    public var displayName: String {
        switch self {
        case .low: return "Low Impact"
        case .medium: return "Medium Impact"
        case .high: return "High Impact"
        }
    }
    
    public var color: String {
        switch self {
        case .low: return "blue"
        case .medium: return "yellow"
        case .high: return "red"
        }
    }
    
    public var icon: String {
        switch self {
        case .low: return "info.circle"
        case .medium: return "exclamationmark.triangle"
        case .high: return "exclamationmark.octagon.fill"
        }
    }
    
    public var priority: Int {
        switch self {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
    
    /// Determine severity based on occurrence count and impact
    public static func calculate(occurrences: Int, impactsMultipleConcepts: Bool) -> ErrorSeverity {
        if occurrences >= 10 || (impactsMultipleConcepts && occurrences >= 5) {
            return .high
        } else if occurrences >= 5 {
            return .medium
        } else {
            return .low
        }
    }
}

// MARK: - AI Extraction Result

public struct ErrorPatternAnalysis: Codable {
    public var errorType: String
    public var errorCategory: String
    public var description: String
    public var rootCause: String?
    public var remediation: String?
    public var affectedConcepts: [String]
    public var severity: String  // "low", "medium", "high"
    
    enum CodingKeys: String, CodingKey {
        case errorType = "error_type"
        case errorCategory = "error_category"
        case description
        case rootCause = "root_cause"
        case remediation
        case affectedConcepts = "affected_concepts"
        case severity
    }
    
    public func toErrorPattern(studentId: String, classroomId: String?, questionId: String?) -> ErrorPattern {
        return ErrorPattern(
            studentId: studentId,
            classroomId: classroomId,
            errorType: errorType,
            errorCategory: errorCategory,
            severity: severity.lowercased(),
            occurrenceCount: 1,
            firstSeen: Temporal.DateTime.now(),
            lastSeen: Temporal.DateTime.now(),
            affectedConcepts: affectedConcepts,
            exampleQuestionIds: questionId != nil ? [questionId] : nil,
            description: description,
            rootCause: rootCause,
            remediation: remediation,
            isResolved: false,
            resolvedAt: nil,
            detectedAt: Temporal.DateTime.now(),
            lastAnalyzedAt: Temporal.DateTime.now(),
            aiModel: "gpt-4o"
        )
    }
}

// MARK: - Convenience Initializers

extension ErrorPattern {
    /// Create a new error pattern with defaults
    public static func createNew(
        studentId: String,
        classroomId: String? = nil,
        errorType: String,
        errorCategory: String,
        description: String,
        affectedConcepts: [String],
        severity: ErrorSeverity = .medium,
        questionId: String? = nil
    ) -> ErrorPattern {
        return ErrorPattern(
            studentId: studentId,
            classroomId: classroomId,
            errorType: errorType,
            errorCategory: errorCategory,
            severity: severity.rawValue,
            occurrenceCount: 1,
            firstSeen: Temporal.DateTime.now(),
            lastSeen: Temporal.DateTime.now(),
            affectedConcepts: affectedConcepts,
            exampleQuestionIds: questionId != nil ? [questionId] : nil,
            description: description,
            rootCause: nil,
            remediation: nil,
            isResolved: false,
            resolvedAt: nil,
            detectedAt: Temporal.DateTime.now(),
            lastAnalyzedAt: Temporal.DateTime.now(),
            aiModel: nil
        )
    }
}
