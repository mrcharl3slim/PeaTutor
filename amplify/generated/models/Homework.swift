// swiftlint:disable all
import Amplify
import Foundation

public struct Homework: Model {
  public let id: String
  public var teacherId: String
  public var title: String
  public var description: String?
  public var dueDate: Temporal.DateTime
  public var assignedDate: Temporal.DateTime
  public var totalPoints: Int?
  public var isPublished: Bool
  public var worksheet: Worksheet?
  public var instructions: String?
  public var learningObjectives: String?
  public var allowLateSubmissions: Bool?
  public var allowMultipleAttempts: Bool?
  public var maxAttempts: Int?
  public var classroom: Classroom?
  public var submissions: List<FullWorksheetSolution>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      teacherId: String,
      title: String,
      description: String? = nil,
      dueDate: Temporal.DateTime,
      assignedDate: Temporal.DateTime,
      totalPoints: Int? = nil,
      isPublished: Bool,
      worksheet: Worksheet? = nil,
      instructions: String? = nil,
      learningObjectives: String? = nil,
      allowLateSubmissions: Bool? = nil,
      allowMultipleAttempts: Bool? = nil,
      maxAttempts: Int? = nil,
      classroom: Classroom? = nil,
      submissions: List<FullWorksheetSolution>? = []) {
    self.init(id: id,
      teacherId: teacherId,
      title: title,
      description: description,
      dueDate: dueDate,
      assignedDate: assignedDate,
      totalPoints: totalPoints,
      isPublished: isPublished,
      worksheet: worksheet,
      instructions: instructions,
      learningObjectives: learningObjectives,
      allowLateSubmissions: allowLateSubmissions,
      allowMultipleAttempts: allowMultipleAttempts,
      maxAttempts: maxAttempts,
      classroom: classroom,
      submissions: submissions,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      teacherId: String,
      title: String,
      description: String? = nil,
      dueDate: Temporal.DateTime,
      assignedDate: Temporal.DateTime,
      totalPoints: Int? = nil,
      isPublished: Bool,
      worksheet: Worksheet? = nil,
      instructions: String? = nil,
      learningObjectives: String? = nil,
      allowLateSubmissions: Bool? = nil,
      allowMultipleAttempts: Bool? = nil,
      maxAttempts: Int? = nil,
      classroom: Classroom? = nil,
      submissions: List<FullWorksheetSolution>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.teacherId = teacherId
      self.title = title
      self.description = description
      self.dueDate = dueDate
      self.assignedDate = assignedDate
      self.totalPoints = totalPoints
      self.isPublished = isPublished
      self.worksheet = worksheet
      self.instructions = instructions
      self.learningObjectives = learningObjectives
      self.allowLateSubmissions = allowLateSubmissions
      self.allowMultipleAttempts = allowMultipleAttempts
      self.maxAttempts = maxAttempts
      self.classroom = classroom
      self.submissions = submissions
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}