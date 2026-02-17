// swiftlint:disable all
import Amplify
import Foundation

public struct ClassroomMembership: Model {
  public let id: String
  public var studentId: String
  public var status: MembershipStatus
  public var enrolledAt: Temporal.DateTime
  public var approvedAt: Temporal.DateTime?
  public var approvedBy: String?
  public var classroom: Classroom?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      studentId: String,
      status: MembershipStatus,
      enrolledAt: Temporal.DateTime,
      approvedAt: Temporal.DateTime? = nil,
      approvedBy: String? = nil,
      classroom: Classroom? = nil) {
    self.init(id: id,
      studentId: studentId,
      status: status,
      enrolledAt: enrolledAt,
      approvedAt: approvedAt,
      approvedBy: approvedBy,
      classroom: classroom,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      studentId: String,
      status: MembershipStatus,
      enrolledAt: Temporal.DateTime,
      approvedAt: Temporal.DateTime? = nil,
      approvedBy: String? = nil,
      classroom: Classroom? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.studentId = studentId
      self.status = status
      self.enrolledAt = enrolledAt
      self.approvedAt = approvedAt
      self.approvedBy = approvedBy
      self.classroom = classroom
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}