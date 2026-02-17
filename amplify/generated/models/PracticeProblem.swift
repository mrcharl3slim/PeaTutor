// swiftlint:disable all
import Amplify
import Foundation

public struct PracticeProblem: Model {
  public let id: String
  public var sourceWorksheetId: String
  public var sourceQuestionId: String?
  public var userId: String
  public var problemText: String
  public var answer: String
  public var stepByStep: String?
  public var hints: [String?]?
  public var concept: String
  public var difficultyLevel: String
  public var questionType: String
  public var generatedFrom: String
  public var difficultyAdjustment: String?
  public var timesUsed: Int
  public var averageScore: Double?
  public var curriculumCode: String?
  public var curriculumGradeLevel: String?
  public var curriculumGradeLevelCode: String?
  public var curriculumStrand: String?
  public var curriculumSubStrand: String?
  public var respectsGradeBoundary: Bool?
  public var targetCurriculumCodes: [String?]?
  public var generatedAt: Temporal.DateTime
  public var aiModel: String
  public var tokensUsed: Int?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      sourceWorksheetId: String,
      sourceQuestionId: String? = nil,
      userId: String,
      problemText: String,
      answer: String,
      stepByStep: String? = nil,
      hints: [String?]? = nil,
      concept: String,
      difficultyLevel: String,
      questionType: String,
      generatedFrom: String,
      difficultyAdjustment: String? = nil,
      timesUsed: Int,
      averageScore: Double? = nil,
      curriculumCode: String? = nil,
      curriculumGradeLevel: String? = nil,
      curriculumGradeLevelCode: String? = nil,
      curriculumStrand: String? = nil,
      curriculumSubStrand: String? = nil,
      respectsGradeBoundary: Bool? = nil,
      targetCurriculumCodes: [String?]? = nil,
      generatedAt: Temporal.DateTime,
      aiModel: String,
      tokensUsed: Int? = nil) {
    self.init(id: id,
      sourceWorksheetId: sourceWorksheetId,
      sourceQuestionId: sourceQuestionId,
      userId: userId,
      problemText: problemText,
      answer: answer,
      stepByStep: stepByStep,
      hints: hints,
      concept: concept,
      difficultyLevel: difficultyLevel,
      questionType: questionType,
      generatedFrom: generatedFrom,
      difficultyAdjustment: difficultyAdjustment,
      timesUsed: timesUsed,
      averageScore: averageScore,
      curriculumCode: curriculumCode,
      curriculumGradeLevel: curriculumGradeLevel,
      curriculumGradeLevelCode: curriculumGradeLevelCode,
      curriculumStrand: curriculumStrand,
      curriculumSubStrand: curriculumSubStrand,
      respectsGradeBoundary: respectsGradeBoundary,
      targetCurriculumCodes: targetCurriculumCodes,
      generatedAt: generatedAt,
      aiModel: aiModel,
      tokensUsed: tokensUsed,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      sourceWorksheetId: String,
      sourceQuestionId: String? = nil,
      userId: String,
      problemText: String,
      answer: String,
      stepByStep: String? = nil,
      hints: [String?]? = nil,
      concept: String,
      difficultyLevel: String,
      questionType: String,
      generatedFrom: String,
      difficultyAdjustment: String? = nil,
      timesUsed: Int,
      averageScore: Double? = nil,
      curriculumCode: String? = nil,
      curriculumGradeLevel: String? = nil,
      curriculumGradeLevelCode: String? = nil,
      curriculumStrand: String? = nil,
      curriculumSubStrand: String? = nil,
      respectsGradeBoundary: Bool? = nil,
      targetCurriculumCodes: [String?]? = nil,
      generatedAt: Temporal.DateTime,
      aiModel: String,
      tokensUsed: Int? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.sourceWorksheetId = sourceWorksheetId
      self.sourceQuestionId = sourceQuestionId
      self.userId = userId
      self.problemText = problemText
      self.answer = answer
      self.stepByStep = stepByStep
      self.hints = hints
      self.concept = concept
      self.difficultyLevel = difficultyLevel
      self.questionType = questionType
      self.generatedFrom = generatedFrom
      self.difficultyAdjustment = difficultyAdjustment
      self.timesUsed = timesUsed
      self.averageScore = averageScore
      self.curriculumCode = curriculumCode
      self.curriculumGradeLevel = curriculumGradeLevel
      self.curriculumGradeLevelCode = curriculumGradeLevelCode
      self.curriculumStrand = curriculumStrand
      self.curriculumSubStrand = curriculumSubStrand
      self.respectsGradeBoundary = respectsGradeBoundary
      self.targetCurriculumCodes = targetCurriculumCodes
      self.generatedAt = generatedAt
      self.aiModel = aiModel
      self.tokensUsed = tokensUsed
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}