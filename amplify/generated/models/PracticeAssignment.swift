// swiftlint:disable all
import Amplify
import Foundation

public struct PracticeAssignment: Model {
  public let id: String
  public var assignedByUserId: String
  public var assignedByRole: String
  public var studentId: String
  public var classroomId: String?
  public var title: String
  public var description: String?
  public var dueDate: Temporal.DateTime?
  public var assignedDate: Temporal.DateTime
  public var problemIds: [String]
  public var problemCount: Int
  public var curriculumCodes: [String?]?
  public var curriculumGradeLevel: String?
  public var targetConcepts: [String?]?
  public var sourceType: String
  public var status: String
  public var startedAt: Temporal.DateTime?
  public var completedAt: Temporal.DateTime?
  public var correctCount: Int?
  public var totalAttempted: Int?
  public var score: Double?
  public var timeSpentSeconds: Int?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      assignedByUserId: String,
      assignedByRole: String,
      studentId: String,
      classroomId: String? = nil,
      title: String,
      description: String? = nil,
      dueDate: Temporal.DateTime? = nil,
      assignedDate: Temporal.DateTime,
      problemIds: [String] = [],
      problemCount: Int,
      curriculumCodes: [String?]? = nil,
      curriculumGradeLevel: String? = nil,
      targetConcepts: [String?]? = nil,
      sourceType: String,
      status: String,
      startedAt: Temporal.DateTime? = nil,
      completedAt: Temporal.DateTime? = nil,
      correctCount: Int? = nil,
      totalAttempted: Int? = nil,
      score: Double? = nil,
      timeSpentSeconds: Int? = nil) {
    self.init(id: id,
      assignedByUserId: assignedByUserId,
      assignedByRole: assignedByRole,
      studentId: studentId,
      classroomId: classroomId,
      title: title,
      description: description,
      dueDate: dueDate,
      assignedDate: assignedDate,
      problemIds: problemIds,
      problemCount: problemCount,
      curriculumCodes: curriculumCodes,
      curriculumGradeLevel: curriculumGradeLevel,
      targetConcepts: targetConcepts,
      sourceType: sourceType,
      status: status,
      startedAt: startedAt,
      completedAt: completedAt,
      correctCount: correctCount,
      totalAttempted: totalAttempted,
      score: score,
      timeSpentSeconds: timeSpentSeconds,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      assignedByUserId: String,
      assignedByRole: String,
      studentId: String,
      classroomId: String? = nil,
      title: String,
      description: String? = nil,
      dueDate: Temporal.DateTime? = nil,
      assignedDate: Temporal.DateTime,
      problemIds: [String] = [],
      problemCount: Int,
      curriculumCodes: [String?]? = nil,
      curriculumGradeLevel: String? = nil,
      targetConcepts: [String?]? = nil,
      sourceType: String,
      status: String,
      startedAt: Temporal.DateTime? = nil,
      completedAt: Temporal.DateTime? = nil,
      correctCount: Int? = nil,
      totalAttempted: Int? = nil,
      score: Double? = nil,
      timeSpentSeconds: Int? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.assignedByUserId = assignedByUserId
      self.assignedByRole = assignedByRole
      self.studentId = studentId
      self.classroomId = classroomId
      self.title = title
      self.description = description
      self.dueDate = dueDate
      self.assignedDate = assignedDate
      self.problemIds = problemIds
      self.problemCount = problemCount
      self.curriculumCodes = curriculumCodes
      self.curriculumGradeLevel = curriculumGradeLevel
      self.targetConcepts = targetConcepts
      self.sourceType = sourceType
      self.status = status
      self.startedAt = startedAt
      self.completedAt = completedAt
      self.correctCount = correctCount
      self.totalAttempted = totalAttempted
      self.score = score
      self.timeSpentSeconds = timeSpentSeconds
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}