// swiftlint:disable all
import Amplify
import Foundation

public struct SolutionFeedback: Model {
  public let id: String
  public var worksheetId: String
  public var userId: String
  public var s3SolutionImageKey: String
  public var feedback: String
  public var isCorrect: Bool?
  public var suggestions: [String?]?
  public var attemptNumber: Int
  public var submittedAt: Temporal.DateTime
  public var question: Question?
  public var aiModel: String?
  public var tokensUsed: Int?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      worksheetId: String,
      userId: String,
      s3SolutionImageKey: String,
      feedback: String,
      isCorrect: Bool? = nil,
      suggestions: [String?]? = nil,
      attemptNumber: Int,
      submittedAt: Temporal.DateTime,
      question: Question? = nil,
      aiModel: String? = nil,
      tokensUsed: Int? = nil) {
    self.init(id: id,
      worksheetId: worksheetId,
      userId: userId,
      s3SolutionImageKey: s3SolutionImageKey,
      feedback: feedback,
      isCorrect: isCorrect,
      suggestions: suggestions,
      attemptNumber: attemptNumber,
      submittedAt: submittedAt,
      question: question,
      aiModel: aiModel,
      tokensUsed: tokensUsed,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      worksheetId: String,
      userId: String,
      s3SolutionImageKey: String,
      feedback: String,
      isCorrect: Bool? = nil,
      suggestions: [String?]? = nil,
      attemptNumber: Int,
      submittedAt: Temporal.DateTime,
      question: Question? = nil,
      aiModel: String? = nil,
      tokensUsed: Int? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.worksheetId = worksheetId
      self.userId = userId
      self.s3SolutionImageKey = s3SolutionImageKey
      self.feedback = feedback
      self.isCorrect = isCorrect
      self.suggestions = suggestions
      self.attemptNumber = attemptNumber
      self.submittedAt = submittedAt
      self.question = question
      self.aiModel = aiModel
      self.tokensUsed = tokensUsed
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}