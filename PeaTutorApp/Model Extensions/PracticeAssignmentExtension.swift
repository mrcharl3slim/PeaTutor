//
//  PracticeAssignmentExtension.swift
//  PeaTutorApp
//
//  Created by Charles on 7/12/25.
//
import Foundation
import Amplify

extension PracticeAssignment {
    
    /// Status enum for type-safe access
    public enum Status: String {
        case pending = "pending"
        case inProgress = "in_progress"
        case completed = "completed"
    }
    
    /// Source type enum for type-safe access
    public enum SourceType: String {
        case prerequisiteGap = "prerequisite_gap"
        case recommended = "recommended"
        case weakArea = "weak_area"
        case topic = "topic"
        case selfPractice = "self_practice"
    }
    
    /// Assigner role enum for type-safe access
    public enum AssignerRole: String {
        case teacher = "teacher"
        case parent = "parent"
        case student = "student"
    }
    
    /// Get status as enum
    public var statusEnum: Status {
        Status(rawValue: status) ?? .pending
    }
    
    /// Get source type as enum
    public var sourceTypeEnum: SourceType {
        SourceType(rawValue: sourceType) ?? .selfPractice
    }
    
    /// Get assigner role as enum
    public var assignerRoleEnum: AssignerRole {
        AssignerRole(rawValue: assignedByRole) ?? .student
    }
    
    /// Check if assignment is overdue
    public var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return Date() > dueDate.foundationDate && statusEnum != .completed
    }
    
    /// Check if assignment is self-assigned
    public var isSelfAssigned: Bool {
        assignedByUserId == studentId && assignerRoleEnum == .student
    }
    
    /// Get score as percentage string
    public var scorePercentageString: String {
        guard let score = score else { return "N/A" }
        return "\(Int(score))%"
    }
    
    /// Get time spent as formatted string
    public var timeSpentFormatted: String {
        guard let seconds = timeSpentSeconds else { return "N/A" }
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        if minutes > 0 {
            return "\(minutes)m \(remainingSeconds)s"
        }
        return "\(remainingSeconds)s"
    }
    
    /// Get curriculum codes as non-optional array
    public var curriculumCodesArray: [String] {
        curriculumCodes?.compactMap { $0 } ?? []
    }
    
    /// Get target concepts as non-optional array
    public var targetConceptsArray: [String] {
        targetConcepts?.compactMap { $0 } ?? []
    }
    
    /// Display name for source type
    public var sourceTypeDisplayName: String {
        switch sourceTypeEnum {
        case .prerequisiteGap: return "Prerequisite Gap"
        case .recommended: return "Recommended"
        case .weakArea: return "Weak Area"
        case .topic: return "Topic Practice"
        case .selfPractice: return "Self Practice"
        }
    }
    
    /// Icon for source type
    public var sourceTypeIcon: String {
        switch sourceTypeEnum {
        case .prerequisiteGap: return "exclamationmark.triangle.fill"
        case .recommended: return "lightbulb.fill"
        case .weakArea: return "chart.line.downtrend.xyaxis"
        case .topic: return "book.fill"
        case .selfPractice: return "person.fill"
        }
    }
    
    /// Color name for status
    public var statusColorName: String {
        switch statusEnum {
        case .pending: return "gray"
        case .inProgress: return "orange"
        case .completed: return "green"
        }
    }
    
    /// Icon for status
    public var statusIcon: String {
        switch statusEnum {
        case .pending: return "circle"
        case .inProgress: return "circle.lefthalf.filled"
        case .completed: return "checkmark.circle.fill"
        }
    }
    
    /// Display text for status
    public var statusDisplayText: String {
        switch statusEnum {
        case .pending: return "Pending"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        }
    }
}






