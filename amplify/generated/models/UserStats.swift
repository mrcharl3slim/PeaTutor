// swiftlint:disable all
import Amplify
import Foundation

public struct UserStats: Model {
  public let id: String
  public var userId: String
  public var userRole: UserRole?
  public var totalWorksheets: Int
  public var totalQuestions: Int
  public var totalSolutionsSubmitted: Int
  public var totalFeedbackReceived: Int
  public var averageScore: Double?
  public var correctAnswersCount: Int
  public var totalAttemptsCount: Int
  public var lastActiveAt: Temporal.DateTime?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      userId: String,
      userRole: UserRole? = nil,
      totalWorksheets: Int,
      totalQuestions: Int,
      totalSolutionsSubmitted: Int,
      totalFeedbackReceived: Int,
      averageScore: Double? = nil,
      correctAnswersCount: Int,
      totalAttemptsCount: Int,
      lastActiveAt: Temporal.DateTime? = nil) {
    self.init(id: id,
      userId: userId,
      userRole: userRole,
      totalWorksheets: totalWorksheets,
      totalQuestions: totalQuestions,
      totalSolutionsSubmitted: totalSolutionsSubmitted,
      totalFeedbackReceived: totalFeedbackReceived,
      averageScore: averageScore,
      correctAnswersCount: correctAnswersCount,
      totalAttemptsCount: totalAttemptsCount,
      lastActiveAt: lastActiveAt,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      userId: String,
      userRole: UserRole? = nil,
      totalWorksheets: Int,
      totalQuestions: Int,
      totalSolutionsSubmitted: Int,
      totalFeedbackReceived: Int,
      averageScore: Double? = nil,
      correctAnswersCount: Int,
      totalAttemptsCount: Int,
      lastActiveAt: Temporal.DateTime? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.userId = userId
      self.userRole = userRole
      self.totalWorksheets = totalWorksheets
      self.totalQuestions = totalQuestions
      self.totalSolutionsSubmitted = totalSolutionsSubmitted
      self.totalFeedbackReceived = totalFeedbackReceived
      self.averageScore = averageScore
      self.correctAnswersCount = correctAnswersCount
      self.totalAttemptsCount = totalAttemptsCount
      self.lastActiveAt = lastActiveAt
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}