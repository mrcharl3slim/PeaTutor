// swiftlint:disable all
import Amplify
import Foundation

extension Question {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case userId
    case questionId
    case questionText
    case marks
    case skillsTested
    case hints
    case stepByStep
    case answer
    case isSubpart
    case parentQuestionId
    case worksheet
    case solutionFeedbacks
    case metadata
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let question = Question.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Questions"
    model.syncPluralName = "Questions"
    
    model.attributes(
      .index(fields: ["worksheetId", "questionId"], name: "byWorksheetQuestions"),
      .primaryKey(fields: [question.id])
    )
    
    model.fields(
      .field(question.id, is: .required, ofType: .string),
      .field(question.userId, is: .required, ofType: .string),
      .field(question.questionId, is: .required, ofType: .string),
      .field(question.questionText, is: .required, ofType: .string),
      .field(question.marks, is: .required, ofType: .int),
      .field(question.skillsTested, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(question.hints, is: .optional, ofType: .string),
      .field(question.stepByStep, is: .optional, ofType: .string),
      .field(question.answer, is: .optional, ofType: .string),
      .field(question.isSubpart, is: .required, ofType: .bool),
      .field(question.parentQuestionId, is: .optional, ofType: .string),
      .belongsTo(question.worksheet, is: .optional, ofType: Worksheet.self, targetNames: ["worksheetId"]),
      .hasMany(question.solutionFeedbacks, is: .optional, ofType: SolutionFeedback.self, associatedWith: SolutionFeedback.keys.question),
      .hasMany(question.metadata, is: .optional, ofType: QuestionMetadata.self, associatedWith: QuestionMetadata.keys.question),
      .field(question.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(question.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Question: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}