// swiftlint:disable all
import Amplify
import Foundation

extension QuestionMetadata {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case userId
    case questionType
    case difficultyLevel
    case cognitiveLevel
    case primaryConcept
    case secondaryConcepts
    case prerequisiteSkills
    case commonMistakes
    case conceptualChallenges
    case hasMultipleSteps
    case requiresVisualization
    case isWordProblem
    case question
    case extractedAt
    case aiModel
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let questionMetadata = QuestionMetadata.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .private, operations: [.read])
    ]
    
    model.listPluralName = "QuestionMetadata"
    model.syncPluralName = "QuestionMetadata"
    
    model.attributes(
      .index(fields: ["questionId"], name: "byQuestion"),
      .primaryKey(fields: [questionMetadata.id])
    )
    
    model.fields(
      .field(questionMetadata.id, is: .required, ofType: .string),
      .field(questionMetadata.userId, is: .required, ofType: .string),
      .field(questionMetadata.questionType, is: .required, ofType: .string),
      .field(questionMetadata.difficultyLevel, is: .required, ofType: .string),
      .field(questionMetadata.cognitiveLevel, is: .required, ofType: .string),
      .field(questionMetadata.primaryConcept, is: .required, ofType: .string),
      .field(questionMetadata.secondaryConcepts, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(questionMetadata.prerequisiteSkills, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(questionMetadata.commonMistakes, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(questionMetadata.conceptualChallenges, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(questionMetadata.hasMultipleSteps, is: .required, ofType: .bool),
      .field(questionMetadata.requiresVisualization, is: .required, ofType: .bool),
      .field(questionMetadata.isWordProblem, is: .required, ofType: .bool),
      .belongsTo(questionMetadata.question, is: .optional, ofType: Question.self, targetNames: ["questionId"]),
      .field(questionMetadata.extractedAt, is: .required, ofType: .dateTime),
      .field(questionMetadata.aiModel, is: .required, ofType: .string),
      .field(questionMetadata.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(questionMetadata.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension QuestionMetadata: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}