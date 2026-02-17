// File: Extensions/EnumExtensions.swift
// Extensions for Amplify-generated enums
// DO NOT redeclare enums - only extend them

import Foundation
import Amplify
import SwiftUI

// MARK: - UserRole Extensions

extension UserRole {
    var displayName: String {
        switch self {
        case .teacher: return "Teacher"
        case .student: return "Student"
        case .parent: return "Parent"
        }
    }

    static var allRoles: [UserRole] {
        [.teacher, .student, .parent]
    }
    
    var icon: String {
        switch self {
        case .teacher: return "person.text.rectangle"
        case .student: return "graduationcap"
        case .parent: return "figure.2.and.child.holdinghands"
        }
    }
    
    var description: String {
        switch self {
        case .teacher:
            return "Create classes, assign homework, and track student progress"
        case .student:
            return "Join classes, submit homework, and receive feedback"
        case .parent:
            return "Monitor your children's academic progress"
        }
    }
    
    // Permission checks
    var canCreateClassrooms: Bool {
        self == .teacher
    }
    
    var canJoinClassrooms: Bool {
        self == .student
    }
    
    var canLinkChildren: Bool {
        self == .parent
    }
    
    var canAssignHomework: Bool {
        self == .teacher
    }
    
    var canSubmitHomework: Bool {
        self == .student
    }
    
    var canViewChildProgress: Bool {
        self == .parent
    }
    
    // UI helpers
    var primaryColor: Color {
        switch self {
        case .teacher: return .blue
        case .student: return .green
        case .parent: return .purple
        }
    }
    
    var onboardingSteps: [String] {
        switch self {
        case .teacher:
            return [
                "Create your first classroom",
                "Generate a class code",
                "Invite students to join",
                "Assign your first homework"
            ]
        case .student:
            return [
                "Join a classroom using class code",
                "Complete your profile",
                "Start working on assignments",
                "Track your progress"
            ]
        case .parent:
            return [
                "Generate a linking code",
                "Share code with your child",
                "Wait for approval",
                "Monitor their progress"
            ]
        }
    }
    
    var availableFeatures: [String] {
        switch self {
        case .teacher:
            return [
                "Create & manage classrooms",
                "Upload worksheets",
                "Assign homework",
                "Review submissions",
                "Track student analytics",
                "Generate class reports"
            ]
        case .student:
            return [
                "Join classrooms",
                "Upload solutions",
                "Get AI feedback",
                "Submit homework",
                "Track your progress",
                "View grades"
            ]
        case .parent:
            return [
                "Link child accounts",
                "View child's classes",
                "Monitor homework completion",
                "View performance analytics",
                "Receive progress reports"
            ]
        }
    }
}

// MARK: - MembershipStatus Extensions

extension MembershipStatus {
    var displayName: String {
        switch self {
        case .pending: return "Pending Approval"
        case .approved: return "Active"
        case .rejected: return "Rejected"
        case .inactive: return "Inactive"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .approved: return "green"
        case .rejected: return "red"
        case .inactive: return "gray"
        }
    }
    
    var swiftUIColor: Color {
        switch self {
        case .pending: return .orange
        case .approved: return .green
        case .rejected: return .red
        case .inactive: return .gray
        }
    }
    
    var badgeIcon: String {
        switch self {
        case .pending: return "clock"
        case .approved: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        case .inactive: return "minus.circle.fill"
        }
    }
    
    var userMessage: String {
        switch self {
        case .pending:
            return "Your request is awaiting teacher approval"
        case .approved:
            return "You're an active member of this classroom"
        case .rejected:
            return "Your request was declined by the teacher"
        case .inactive:
            return "This membership is no longer active"
        }
    }
    
    var teacherActionLabel: String? {
        switch self {
        case .pending: return "Review Request"
        case .approved: return "Remove Student"
        case .rejected: return "Reconsider"
        case .inactive: return "Reactivate"
        }
    }
    
    var isActive: Bool {
        self == .approved
    }
    
    var canTransitionTo: [MembershipStatus] {
        switch self {
        case .pending: return [.approved, .rejected]
        case .approved: return [.inactive]
        case .rejected: return [.pending]
        case .inactive: return [.approved]
        }
    }
    
    func canTransition(to newStatus: MembershipStatus) -> Bool {
        canTransitionTo.contains(newStatus)
    }
}

// MARK: - RelationshipType Extensions

extension RelationshipType {
    var displayName: String {
        switch self {
        case .parent: return "Parent"
        case .guardian: return "Guardian"
        case .tutor: return "Tutor"
        }
    }
    
    var icon: String {
        switch self {
        case .parent: return "figure.2.and.child.holdinghands"
        case .guardian: return "person.2.fill"
        case .tutor: return "person.crop.circle.badge.checkmark"
        }
    }
    
    var description: String {
        switch self {
        case .parent:
            return "Biological or adoptive parent"
        case .guardian:
            return "Legal guardian or caretaker"
        case .tutor:
            return "Private tutor or instructor"
        }
    }
    
    var canViewGrades: Bool {
        switch self {
        case .parent, .guardian: return true
        case .tutor: return false
        }
    }
    
    var canReceiveReports: Bool {
        true
    }
    
    var requiresChildApproval: Bool {
        true
    }
}

// MARK: - LinkStatus Extensions

extension LinkStatus {
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .approved: return "Linked"
        case .rejected: return "Rejected"
        case .revoked: return "Revoked"
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "clock.badge.questionmark"
        case .approved: return "link.circle.fill"
        case .rejected: return "xmark.circle.fill"
        case .revoked: return "link.badge.minus"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .approved: return .green
        case .rejected: return .red
        case .revoked: return .gray
        }
    }
    
    var childMessage: String {
        switch self {
        case .pending:
            return "Someone wants to link as your parent/guardian. Review the request."
        case .approved:
            return "Successfully linked. They can now monitor your progress."
        case .rejected:
            return "You declined this linking request."
        case .revoked:
            return "This link has been removed."
        }
    }
    
    var parentMessage: String {
        switch self {
        case .pending:
            return "Waiting for your child to approve the link."
        case .approved:
            return "Successfully linked. You can now monitor their progress."
        case .rejected:
            return "Your child declined the linking request."
        case .revoked:
            return "This link has been removed."
        }
    }
    
    var isActive: Bool {
        self == .approved
    }
    
    var canViewProgress: Bool {
        self == .approved
    }
    
    var canTransitionTo: [LinkStatus] {
        switch self {
        case .pending: return [.approved, .rejected]
        case .approved: return [.revoked]
        case .rejected: return []
        case .revoked: return []
        }
    }
    
    func canTransition(to newStatus: LinkStatus) -> Bool {
        canTransitionTo.contains(newStatus)
    }
}

// MARK: - SubmissionStatus Extensions

extension SubmissionStatus {
    var displayName: String {
        switch self {
        case .notStarted: return "Not Started"
        case .inProgress: return "In Progress"
        case .submitted: return "Submitted"
        case .reviewed: return "Reviewed"
        case .late: return "Late"
        }
    }
    
    var color: String {
        switch self {
        case .notStarted: return "gray"
        case .inProgress: return "blue"
        case .submitted: return "orange"
        case .reviewed: return "green"
        case .late: return "red"
        }
    }
    
    var swiftUIColor: Color {
        switch self {
        case .notStarted: return .gray
        case .inProgress: return .blue
        case .submitted: return .orange
        case .reviewed: return .green
        case .late: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .notStarted: return "circle"
        case .inProgress: return "pencil.circle"
        case .submitted: return "paperplane.circle.fill"
        case .reviewed: return "checkmark.circle.fill"
        case .late: return "exclamationmark.triangle.fill"
        }
    }
    
    var progressValue: Double {
        switch self {
        case .notStarted: return 0.0
        case .inProgress: return 0.5
        case .submitted: return 0.75
        case .reviewed: return 1.0
        case .late: return 0.0
        }
    }
    
    var studentMessage: String {
        switch self {
        case .notStarted:
            return "You haven't started this assignment yet"
        case .inProgress:
            return "Keep working on your assignment"
        case .submitted:
            return "Submitted! Waiting for teacher review"
        case .reviewed:
            return "Your teacher has reviewed your work"
        case .late:
            return "This assignment is overdue"
        }
    }
    
    var teacherMessage: String {
        switch self {
        case .notStarted:
            return "Student hasn't started"
        case .inProgress:
            return "Student is working on this"
        case .submitted:
            return "Ready for review"
        case .reviewed:
            return "Feedback provided"
        case .late:
            return "Submitted after deadline"
        }
    }
    
    var canEdit: Bool {
        switch self {
        case .notStarted, .inProgress: return true
        case .submitted, .reviewed, .late: return false
        }
    }
    
    var canSubmit: Bool {
        switch self {
        case .notStarted, .inProgress: return true
        case .submitted, .reviewed, .late: return false
        }
    }
    
    var canReview: Bool {
        switch self {
        case .submitted, .late: return true
        case .notStarted, .inProgress, .reviewed: return false
        }
    }
    
    var nextStatus: SubmissionStatus? {
        switch self {
        case .notStarted: return .inProgress
        case .inProgress: return .submitted
        case .submitted: return .reviewed
        case .reviewed: return nil
        case .late: return .reviewed
        }
    }
    
    var reviewPriority: Int {
        switch self {
        case .submitted: return 1
        case .late: return 2
        case .reviewed: return 3
        case .inProgress: return 4
        case .notStarted: return 5
        }
    }
    
    static func determine(submittedAt: Date?, dueDate: Date) -> SubmissionStatus {
        guard let submitted = submittedAt else {
            return Date() > dueDate ? .late : .notStarted
        }
        return submitted > dueDate ? .late : .submitted
    }
}
