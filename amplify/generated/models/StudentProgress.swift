// swiftlint:disable all
import Amplify
import Foundation

public struct StudentProgress: Model {
  public let id: String
  public var studentId: String
  public var classroom: Classroom?
  public var totalHomeworkAssigned: Int
  public var totalHomeworkCompleted: Int
  public var totalHomeworkLate: Int
  public var totalSubmissions: Int
  public var averageAttemptsPerHomework: Double?
  public var currentStreak: Int?
  public var longestStreak: Int?
  public var skillsBreakdown: String?
  public var strengthAreas: [String?]?
  public var improvementAreas: [String?]?
  public var lastSubmissionAt: Temporal.DateTime?
  public var progressUpdatedAt: Temporal.DateTime?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      studentId: String,
      classroom: Classroom? = nil,
      totalHomeworkAssigned: Int,
      totalHomeworkCompleted: Int,
      totalHomeworkLate: Int,
      totalSubmissions: Int,
      averageAttemptsPerHomework: Double? = nil,
      currentStreak: Int? = nil,
      longestStreak: Int? = nil,
      skillsBreakdown: String? = nil,
      strengthAreas: [String?]? = nil,
      improvementAreas: [String?]? = nil,
      lastSubmissionAt: Temporal.DateTime? = nil,
      progressUpdatedAt: Temporal.DateTime? = nil) {
    self.init(id: id,
      studentId: studentId,
      classroom: classroom,
      totalHomeworkAssigned: totalHomeworkAssigned,
      totalHomeworkCompleted: totalHomeworkCompleted,
      totalHomeworkLate: totalHomeworkLate,
      totalSubmissions: totalSubmissions,
      averageAttemptsPerHomework: averageAttemptsPerHomework,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      skillsBreakdown: skillsBreakdown,
      strengthAreas: strengthAreas,
      improvementAreas: improvementAreas,
      lastSubmissionAt: lastSubmissionAt,
      progressUpdatedAt: progressUpdatedAt,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      studentId: String,
      classroom: Classroom? = nil,
      totalHomeworkAssigned: Int,
      totalHomeworkCompleted: Int,
      totalHomeworkLate: Int,
      totalSubmissions: Int,
      averageAttemptsPerHomework: Double? = nil,
      currentStreak: Int? = nil,
      longestStreak: Int? = nil,
      skillsBreakdown: String? = nil,
      strengthAreas: [String?]? = nil,
      improvementAreas: [String?]? = nil,
      lastSubmissionAt: Temporal.DateTime? = nil,
      progressUpdatedAt: Temporal.DateTime? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.studentId = studentId
      self.classroom = classroom
      self.totalHomeworkAssigned = totalHomeworkAssigned
      self.totalHomeworkCompleted = totalHomeworkCompleted
      self.totalHomeworkLate = totalHomeworkLate
      self.totalSubmissions = totalSubmissions
      self.averageAttemptsPerHomework = averageAttemptsPerHomework
      self.currentStreak = currentStreak
      self.longestStreak = longestStreak
      self.skillsBreakdown = skillsBreakdown
      self.strengthAreas = strengthAreas
      self.improvementAreas = improvementAreas
      self.lastSubmissionAt = lastSubmissionAt
      self.progressUpdatedAt = progressUpdatedAt
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}