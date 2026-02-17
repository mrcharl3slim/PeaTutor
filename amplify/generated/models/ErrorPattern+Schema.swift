// swiftlint:disable all
import Amplify
import Foundation

extension ErrorPattern {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case studentId
    case classroomId
    case errorType
    case errorCategory
    case severity
    case occurrenceCount
    case firstSeen
    case lastSeen
    case affectedConcepts
    case exampleQuestionIds
    case description
    case rootCause
    case remediation
    case isResolved
    case resolvedAt
    case detectedAt
    case lastAnalyzedAt
    case aiModel
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let errorPattern = ErrorPattern.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "studentId", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .private, operations: [.read])
    ]
    
    model.listPluralName = "ErrorPatterns"
    model.syncPluralName = "ErrorPatterns"
    
    model.attributes(
      .index(fields: ["studentId", "detectedAt"], name: "byStudent"),
      .index(fields: ["classroomId"], name: "byClassroom"),
      .primaryKey(fields: [errorPattern.id])
    )
    
    model.fields(
      .field(errorPattern.id, is: .required, ofType: .string),
      .field(errorPattern.studentId, is: .required, ofType: .string),
      .field(errorPattern.classroomId, is: .optional, ofType: .string),
      .field(errorPattern.errorType, is: .required, ofType: .string),
      .field(errorPattern.errorCategory, is: .required, ofType: .string),
      .field(errorPattern.severity, is: .required, ofType: .string),
      .field(errorPattern.occurrenceCount, is: .required, ofType: .int),
      .field(errorPattern.firstSeen, is: .required, ofType: .dateTime),
      .field(errorPattern.lastSeen, is: .required, ofType: .dateTime),
      .field(errorPattern.affectedConcepts, is: .required, ofType: .embeddedCollection(of: String.self)),
      .field(errorPattern.exampleQuestionIds, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(errorPattern.description, is: .required, ofType: .string),
      .field(errorPattern.rootCause, is: .optional, ofType: .string),
      .field(errorPattern.remediation, is: .optional, ofType: .string),
      .field(errorPattern.isResolved, is: .required, ofType: .bool),
      .field(errorPattern.resolvedAt, is: .optional, ofType: .dateTime),
      .field(errorPattern.detectedAt, is: .required, ofType: .dateTime),
      .field(errorPattern.lastAnalyzedAt, is: .required, ofType: .dateTime),
      .field(errorPattern.aiModel, is: .optional, ofType: .string),
      .field(errorPattern.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(errorPattern.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension ErrorPattern: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}