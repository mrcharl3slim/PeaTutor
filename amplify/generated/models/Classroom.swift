// swiftlint:disable all
import Amplify
import Foundation

public struct Classroom: Model {
  public let id: String
  public var teacherId: String
  public var className: String
  public var classCode: String
  public var subject: String?
  public var description: String?
  public var gradeLevel: String?
  public var isActive: Bool
  public var memberships: List<ClassroomMembership>?
  public var homework: List<Homework>?
  public var studentProgress: List<StudentProgress>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      teacherId: String,
      className: String,
      classCode: String,
      subject: String? = nil,
      description: String? = nil,
      gradeLevel: String? = nil,
      isActive: Bool,
      memberships: List<ClassroomMembership>? = [],
      homework: List<Homework>? = [],
      studentProgress: List<StudentProgress>? = []) {
    self.init(id: id,
      teacherId: teacherId,
      className: className,
      classCode: classCode,
      subject: subject,
      description: description,
      gradeLevel: gradeLevel,
      isActive: isActive,
      memberships: memberships,
      homework: homework,
      studentProgress: studentProgress,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      teacherId: String,
      className: String,
      classCode: String,
      subject: String? = nil,
      description: String? = nil,
      gradeLevel: String? = nil,
      isActive: Bool,
      memberships: List<ClassroomMembership>? = [],
      homework: List<Homework>? = [],
      studentProgress: List<StudentProgress>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.teacherId = teacherId
      self.className = className
      self.classCode = classCode
      self.subject = subject
      self.description = description
      self.gradeLevel = gradeLevel
      self.isActive = isActive
      self.memberships = memberships
      self.homework = homework
      self.studentProgress = studentProgress
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}