// swiftlint:disable all
import Amplify
import Foundation

public struct FullWorksheetSolution: Model {
  public let id: String
  public var userId: String
  public var s3SolutionImageKey: String
  public var overallFeedback: String
  public var overallScore: Int
  public var totalQuestions: Int
  public var completedQuestions: [String?]?
  public var questionsWithIssues: [String?]?
  public var suggestions: [String?]?
  public var detailedFeedback: String?
  public var attemptNumber: Int
  public var submittedAt: Temporal.DateTime
  public var worksheet: Worksheet?
  public var aiModel: String?
  public var tokensUsed: Int?
  public var homework: Homework?
  public var isLate: Bool?
  public var teacherReviewed: Bool?
  public var teacherNotes: String?
  public var teacherReviewedAt: Temporal.DateTime?
  public var teacherReviewedBy: String?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      userId: String,
      s3SolutionImageKey: String,
      overallFeedback: String,
      overallScore: Int,
      totalQuestions: Int,
      completedQuestions: [String?]? = nil,
      questionsWithIssues: [String?]? = nil,
      suggestions: [String?]? = nil,
      detailedFeedback: String? = nil,
      attemptNumber: Int,
      submittedAt: Temporal.DateTime,
      worksheet: Worksheet? = nil,
      aiModel: String? = nil,
      tokensUsed: Int? = nil,
      homework: Homework? = nil,
      isLate: Bool? = nil,
      teacherReviewed: Bool? = nil,
      teacherNotes: String? = nil,
      teacherReviewedAt: Temporal.DateTime? = nil,
      teacherReviewedBy: String? = nil) {
    self.init(id: id,
      userId: userId,
      s3SolutionImageKey: s3SolutionImageKey,
      overallFeedback: overallFeedback,
      overallScore: overallScore,
      totalQuestions: totalQuestions,
      completedQuestions: completedQuestions,
      questionsWithIssues: questionsWithIssues,
      suggestions: suggestions,
      detailedFeedback: detailedFeedback,
      attemptNumber: attemptNumber,
      submittedAt: submittedAt,
      worksheet: worksheet,
      aiModel: aiModel,
      tokensUsed: tokensUsed,
      homework: homework,
      isLate: isLate,
      teacherReviewed: teacherReviewed,
      teacherNotes: teacherNotes,
      teacherReviewedAt: teacherReviewedAt,
      teacherReviewedBy: teacherReviewedBy,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      userId: String,
      s3SolutionImageKey: String,
      overallFeedback: String,
      overallScore: Int,
      totalQuestions: Int,
      completedQuestions: [String?]? = nil,
      questionsWithIssues: [String?]? = nil,
      suggestions: [String?]? = nil,
      detailedFeedback: String? = nil,
      attemptNumber: Int,
      submittedAt: Temporal.DateTime,
      worksheet: Worksheet? = nil,
      aiModel: String? = nil,
      tokensUsed: Int? = nil,
      homework: Homework? = nil,
      isLate: Bool? = nil,
      teacherReviewed: Bool? = nil,
      teacherNotes: String? = nil,
      teacherReviewedAt: Temporal.DateTime? = nil,
      teacherReviewedBy: String? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.userId = userId
      self.s3SolutionImageKey = s3SolutionImageKey
      self.overallFeedback = overallFeedback
      self.overallScore = overallScore
      self.totalQuestions = totalQuestions
      self.completedQuestions = completedQuestions
      self.questionsWithIssues = questionsWithIssues
      self.suggestions = suggestions
      self.detailedFeedback = detailedFeedback
      self.attemptNumber = attemptNumber
      self.submittedAt = submittedAt
      self.worksheet = worksheet
      self.aiModel = aiModel
      self.tokensUsed = tokensUsed
      self.homework = homework
      self.isLate = isLate
      self.teacherReviewed = teacherReviewed
      self.teacherNotes = teacherNotes
      self.teacherReviewedAt = teacherReviewedAt
      self.teacherReviewedBy = teacherReviewedBy
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}