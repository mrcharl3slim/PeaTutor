// swiftlint:disable all
import Amplify
import Foundation

public struct Question: Model {
  public let id: String
  public var userId: String
  public var questionId: String
  public var questionText: String
  public var marks: Int
  public var skillsTested: [String?]?
  public var hints: String?
  public var stepByStep: String?
  public var answer: String?
  public var isSubpart: Bool
  public var parentQuestionId: String?
  public var worksheet: Worksheet?
  public var solutionFeedbacks: List<SolutionFeedback>?
  public var metadata: List<QuestionMetadata>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      userId: String,
      questionId: String,
      questionText: String,
      marks: Int,
      skillsTested: [String?]? = nil,
      hints: String? = nil,
      stepByStep: String? = nil,
      answer: String? = nil,
      isSubpart: Bool,
      parentQuestionId: String? = nil,
      worksheet: Worksheet? = nil,
      solutionFeedbacks: List<SolutionFeedback>? = [],
      metadata: List<QuestionMetadata>? = []) {
    self.init(id: id,
      userId: userId,
      questionId: questionId,
      questionText: questionText,
      marks: marks,
      skillsTested: skillsTested,
      hints: hints,
      stepByStep: stepByStep,
      answer: answer,
      isSubpart: isSubpart,
      parentQuestionId: parentQuestionId,
      worksheet: worksheet,
      solutionFeedbacks: solutionFeedbacks,
      metadata: metadata,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      userId: String,
      questionId: String,
      questionText: String,
      marks: Int,
      skillsTested: [String?]? = nil,
      hints: String? = nil,
      stepByStep: String? = nil,
      answer: String? = nil,
      isSubpart: Bool,
      parentQuestionId: String? = nil,
      worksheet: Worksheet? = nil,
      solutionFeedbacks: List<SolutionFeedback>? = [],
      metadata: List<QuestionMetadata>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.userId = userId
      self.questionId = questionId
      self.questionText = questionText
      self.marks = marks
      self.skillsTested = skillsTested
      self.hints = hints
      self.stepByStep = stepByStep
      self.answer = answer
      self.isSubpart = isSubpart
      self.parentQuestionId = parentQuestionId
      self.worksheet = worksheet
      self.solutionFeedbacks = solutionFeedbacks
      self.metadata = metadata
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}