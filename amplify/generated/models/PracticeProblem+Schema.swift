// swiftlint:disable all
import Amplify
import Foundation

extension PracticeProblem {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case sourceWorksheetId
    case sourceQuestionId
    case userId
    case problemText
    case answer
    case stepByStep
    case hints
    case concept
    case difficultyLevel
    case questionType
    case generatedFrom
    case difficultyAdjustment
    case timesUsed
    case averageScore
    case curriculumCode
    case curriculumGradeLevel
    case curriculumGradeLevelCode
    case curriculumStrand
    case curriculumSubStrand
    case respectsGradeBoundary
    case targetCurriculumCodes
    case generatedAt
    case aiModel
    case tokensUsed
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let practiceProblem = PracticeProblem.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.read]),
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .read])
    ]
    
    model.listPluralName = "PracticeProblems"
    model.syncPluralName = "PracticeProblems"
    
    model.attributes(
      .index(fields: ["sourceWorksheetId"], name: "bySourceWorksheet"),
      .primaryKey(fields: [practiceProblem.id])
    )
    
    model.fields(
      .field(practiceProblem.id, is: .required, ofType: .string),
      .field(practiceProblem.sourceWorksheetId, is: .required, ofType: .string),
      .field(practiceProblem.sourceQuestionId, is: .optional, ofType: .string),
      .field(practiceProblem.userId, is: .required, ofType: .string),
      .field(practiceProblem.problemText, is: .required, ofType: .string),
      .field(practiceProblem.answer, is: .required, ofType: .string),
      .field(practiceProblem.stepByStep, is: .optional, ofType: .string),
      .field(practiceProblem.hints, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(practiceProblem.concept, is: .required, ofType: .string),
      .field(practiceProblem.difficultyLevel, is: .required, ofType: .string),
      .field(practiceProblem.questionType, is: .required, ofType: .string),
      .field(practiceProblem.generatedFrom, is: .required, ofType: .string),
      .field(practiceProblem.difficultyAdjustment, is: .optional, ofType: .string),
      .field(practiceProblem.timesUsed, is: .required, ofType: .int),
      .field(practiceProblem.averageScore, is: .optional, ofType: .double),
      .field(practiceProblem.curriculumCode, is: .optional, ofType: .string),
      .field(practiceProblem.curriculumGradeLevel, is: .optional, ofType: .string),
      .field(practiceProblem.curriculumGradeLevelCode, is: .optional, ofType: .string),
      .field(practiceProblem.curriculumStrand, is: .optional, ofType: .string),
      .field(practiceProblem.curriculumSubStrand, is: .optional, ofType: .string),
      .field(practiceProblem.respectsGradeBoundary, is: .optional, ofType: .bool),
      .field(practiceProblem.targetCurriculumCodes, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(practiceProblem.generatedAt, is: .required, ofType: .dateTime),
      .field(practiceProblem.aiModel, is: .required, ofType: .string),
      .field(practiceProblem.tokensUsed, is: .optional, ofType: .int),
      .field(practiceProblem.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(practiceProblem.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension PracticeProblem: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}