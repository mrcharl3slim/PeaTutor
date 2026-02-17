// swiftlint:disable all
import Amplify
import Foundation

public struct ErrorPattern: Model {
  public let id: String
  public var studentId: String
  public var classroomId: String?
  public var errorType: String
  public var errorCategory: String
  public var severity: String
  public var occurrenceCount: Int
  public var firstSeen: Temporal.DateTime
  public var lastSeen: Temporal.DateTime
  public var affectedConcepts: [String]
  public var exampleQuestionIds: [String?]?
  public var description: String
  public var rootCause: String?
  public var remediation: String?
  public var isResolved: Bool
  public var resolvedAt: Temporal.DateTime?
  public var detectedAt: Temporal.DateTime
  public var lastAnalyzedAt: Temporal.DateTime
  public var aiModel: String?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      studentId: String,
      classroomId: String? = nil,
      errorType: String,
      errorCategory: String,
      severity: String,
      occurrenceCount: Int,
      firstSeen: Temporal.DateTime,
      lastSeen: Temporal.DateTime,
      affectedConcepts: [String] = [],
      exampleQuestionIds: [String?]? = nil,
      description: String,
      rootCause: String? = nil,
      remediation: String? = nil,
      isResolved: Bool,
      resolvedAt: Temporal.DateTime? = nil,
      detectedAt: Temporal.DateTime,
      lastAnalyzedAt: Temporal.DateTime,
      aiModel: String? = nil) {
    self.init(id: id,
      studentId: studentId,
      classroomId: classroomId,
      errorType: errorType,
      errorCategory: errorCategory,
      severity: severity,
      occurrenceCount: occurrenceCount,
      firstSeen: firstSeen,
      lastSeen: lastSeen,
      affectedConcepts: affectedConcepts,
      exampleQuestionIds: exampleQuestionIds,
      description: description,
      rootCause: rootCause,
      remediation: remediation,
      isResolved: isResolved,
      resolvedAt: resolvedAt,
      detectedAt: detectedAt,
      lastAnalyzedAt: lastAnalyzedAt,
      aiModel: aiModel,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      studentId: String,
      classroomId: String? = nil,
      errorType: String,
      errorCategory: String,
      severity: String,
      occurrenceCount: Int,
      firstSeen: Temporal.DateTime,
      lastSeen: Temporal.DateTime,
      affectedConcepts: [String] = [],
      exampleQuestionIds: [String?]? = nil,
      description: String,
      rootCause: String? = nil,
      remediation: String? = nil,
      isResolved: Bool,
      resolvedAt: Temporal.DateTime? = nil,
      detectedAt: Temporal.DateTime,
      lastAnalyzedAt: Temporal.DateTime,
      aiModel: String? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.studentId = studentId
      self.classroomId = classroomId
      self.errorType = errorType
      self.errorCategory = errorCategory
      self.severity = severity
      self.occurrenceCount = occurrenceCount
      self.firstSeen = firstSeen
      self.lastSeen = lastSeen
      self.affectedConcepts = affectedConcepts
      self.exampleQuestionIds = exampleQuestionIds
      self.description = description
      self.rootCause = rootCause
      self.remediation = remediation
      self.isResolved = isResolved
      self.resolvedAt = resolvedAt
      self.detectedAt = detectedAt
      self.lastAnalyzedAt = lastAnalyzedAt
      self.aiModel = aiModel
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}