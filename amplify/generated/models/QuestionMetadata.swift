// swiftlint:disable all
import Amplify
import Foundation

public struct QuestionMetadata: Model {
  public let id: String
  public var userId: String
  public var questionType: String
  public var difficultyLevel: String
  public var cognitiveLevel: String
  public var primaryConcept: String
  public var secondaryConcepts: [String?]?
  public var prerequisiteSkills: [String?]?
  public var commonMistakes: [String?]?
  public var conceptualChallenges: [String?]?
  public var hasMultipleSteps: Bool
  public var requiresVisualization: Bool
  public var isWordProblem: Bool
  public var question: Question?
  public var extractedAt: Temporal.DateTime
  public var aiModel: String
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      userId: String,
      questionType: String,
      difficultyLevel: String,
      cognitiveLevel: String,
      primaryConcept: String,
      secondaryConcepts: [String?]? = nil,
      prerequisiteSkills: [String?]? = nil,
      commonMistakes: [String?]? = nil,
      conceptualChallenges: [String?]? = nil,
      hasMultipleSteps: Bool,
      requiresVisualization: Bool,
      isWordProblem: Bool,
      question: Question? = nil,
      extractedAt: Temporal.DateTime,
      aiModel: String) {
    self.init(id: id,
      userId: userId,
      questionType: questionType,
      difficultyLevel: difficultyLevel,
      cognitiveLevel: cognitiveLevel,
      primaryConcept: primaryConcept,
      secondaryConcepts: secondaryConcepts,
      prerequisiteSkills: prerequisiteSkills,
      commonMistakes: commonMistakes,
      conceptualChallenges: conceptualChallenges,
      hasMultipleSteps: hasMultipleSteps,
      requiresVisualization: requiresVisualization,
      isWordProblem: isWordProblem,
      question: question,
      extractedAt: extractedAt,
      aiModel: aiModel,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      userId: String,
      questionType: String,
      difficultyLevel: String,
      cognitiveLevel: String,
      primaryConcept: String,
      secondaryConcepts: [String?]? = nil,
      prerequisiteSkills: [String?]? = nil,
      commonMistakes: [String?]? = nil,
      conceptualChallenges: [String?]? = nil,
      hasMultipleSteps: Bool,
      requiresVisualization: Bool,
      isWordProblem: Bool,
      question: Question? = nil,
      extractedAt: Temporal.DateTime,
      aiModel: String,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.userId = userId
      self.questionType = questionType
      self.difficultyLevel = difficultyLevel
      self.cognitiveLevel = cognitiveLevel
      self.primaryConcept = primaryConcept
      self.secondaryConcepts = secondaryConcepts
      self.prerequisiteSkills = prerequisiteSkills
      self.commonMistakes = commonMistakes
      self.conceptualChallenges = conceptualChallenges
      self.hasMultipleSteps = hasMultipleSteps
      self.requiresVisualization = requiresVisualization
      self.isWordProblem = isWordProblem
      self.question = question
      self.extractedAt = extractedAt
      self.aiModel = aiModel
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}