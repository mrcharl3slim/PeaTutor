// swiftlint:disable all
import Amplify
import Foundation

public struct HomeworkAnalytics: Model {
  public let id: String
  public var homeworkId: String
  public var teacherId: String
  public var totalStudents: Int
  public var submittedCount: Int
  public var totalSubmissions: Int
  public var lateCount: Int
  public var averageAttempts: Double?
  public var multipleAttemptsCount: Int?
  public var reviewedCount: Int
  public var pendingReviewCount: Int
  public var commonMistakes: String?
  public var strugglingStudents: [String?]?
  public var lastUpdatedAt: Temporal.DateTime
  public var lastCalculatedAt: Temporal.DateTime?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      homeworkId: String,
      teacherId: String,
      totalStudents: Int,
      submittedCount: Int,
      totalSubmissions: Int,
      lateCount: Int,
      averageAttempts: Double? = nil,
      multipleAttemptsCount: Int? = nil,
      reviewedCount: Int,
      pendingReviewCount: Int,
      commonMistakes: String? = nil,
      strugglingStudents: [String?]? = nil,
      lastUpdatedAt: Temporal.DateTime,
      lastCalculatedAt: Temporal.DateTime? = nil) {
    self.init(id: id,
      homeworkId: homeworkId,
      teacherId: teacherId,
      totalStudents: totalStudents,
      submittedCount: submittedCount,
      totalSubmissions: totalSubmissions,
      lateCount: lateCount,
      averageAttempts: averageAttempts,
      multipleAttemptsCount: multipleAttemptsCount,
      reviewedCount: reviewedCount,
      pendingReviewCount: pendingReviewCount,
      commonMistakes: commonMistakes,
      strugglingStudents: strugglingStudents,
      lastUpdatedAt: lastUpdatedAt,
      lastCalculatedAt: lastCalculatedAt,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      homeworkId: String,
      teacherId: String,
      totalStudents: Int,
      submittedCount: Int,
      totalSubmissions: Int,
      lateCount: Int,
      averageAttempts: Double? = nil,
      multipleAttemptsCount: Int? = nil,
      reviewedCount: Int,
      pendingReviewCount: Int,
      commonMistakes: String? = nil,
      strugglingStudents: [String?]? = nil,
      lastUpdatedAt: Temporal.DateTime,
      lastCalculatedAt: Temporal.DateTime? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.homeworkId = homeworkId
      self.teacherId = teacherId
      self.totalStudents = totalStudents
      self.submittedCount = submittedCount
      self.totalSubmissions = totalSubmissions
      self.lateCount = lateCount
      self.averageAttempts = averageAttempts
      self.multipleAttemptsCount = multipleAttemptsCount
      self.reviewedCount = reviewedCount
      self.pendingReviewCount = pendingReviewCount
      self.commonMistakes = commonMistakes
      self.strugglingStudents = strugglingStudents
      self.lastUpdatedAt = lastUpdatedAt
      self.lastCalculatedAt = lastCalculatedAt
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}