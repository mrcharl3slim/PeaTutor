// swiftlint:disable all
import Amplify
import Foundation

extension SolutionFeedback {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case worksheetId
    case userId
    case s3SolutionImageKey
    case feedback
    case isCorrect
    case suggestions
    case attemptNumber
    case submittedAt
    case question
    case aiModel
    case tokensUsed
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let solutionFeedback = SolutionFeedback.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .private, operations: [.read])
    ]
    
    model.listPluralName = "SolutionFeedbacks"
    model.syncPluralName = "SolutionFeedbacks"
    
    model.attributes(
      .index(fields: ["questionId", "submittedAt"], name: "byQuestionFeedback"),
      .index(fields: ["worksheetId", "submittedAt"], name: "byWorksheetAllFeedback"),
      .primaryKey(fields: [solutionFeedback.id])
    )
    
    model.fields(
      .field(solutionFeedback.id, is: .required, ofType: .string),
      .field(solutionFeedback.worksheetId, is: .required, ofType: .string),
      .field(solutionFeedback.userId, is: .required, ofType: .string),
      .field(solutionFeedback.s3SolutionImageKey, is: .required, ofType: .string),
      .field(solutionFeedback.feedback, is: .required, ofType: .string),
      .field(solutionFeedback.isCorrect, is: .optional, ofType: .bool),
      .field(solutionFeedback.suggestions, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(solutionFeedback.attemptNumber, is: .required, ofType: .int),
      .field(solutionFeedback.submittedAt, is: .required, ofType: .dateTime),
      .belongsTo(solutionFeedback.question, is: .optional, ofType: Question.self, targetNames: ["questionId"]),
      .field(solutionFeedback.aiModel, is: .optional, ofType: .string),
      .field(solutionFeedback.tokensUsed, is: .optional, ofType: .int),
      .field(solutionFeedback.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(solutionFeedback.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension SolutionFeedback: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}