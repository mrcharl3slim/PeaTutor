// swiftlint:disable all
import Amplify
import Foundation

extension HomeworkAnalytics {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case homeworkId
    case teacherId
    case totalStudents
    case submittedCount
    case totalSubmissions
    case lateCount
    case averageAttempts
    case multipleAttemptsCount
    case reviewedCount
    case pendingReviewCount
    case commonMistakes
    case strugglingStudents
    case lastUpdatedAt
    case lastCalculatedAt
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let homeworkAnalytics = HomeworkAnalytics.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.read]),
      rule(allow: .owner, ownerField: "teacherId", identityClaim: "cognito:username", provider: .userPools, operations: [.read, .create, .update, .delete])
    ]
    
    model.listPluralName = "HomeworkAnalytics"
    model.syncPluralName = "HomeworkAnalytics"
    
    model.attributes(
      .index(fields: ["homeworkId"], name: "byHomework"),
      .primaryKey(fields: [homeworkAnalytics.id])
    )
    
    model.fields(
      .field(homeworkAnalytics.id, is: .required, ofType: .string),
      .field(homeworkAnalytics.homeworkId, is: .required, ofType: .string),
      .field(homeworkAnalytics.teacherId, is: .required, ofType: .string),
      .field(homeworkAnalytics.totalStudents, is: .required, ofType: .int),
      .field(homeworkAnalytics.submittedCount, is: .required, ofType: .int),
      .field(homeworkAnalytics.totalSubmissions, is: .required, ofType: .int),
      .field(homeworkAnalytics.lateCount, is: .required, ofType: .int),
      .field(homeworkAnalytics.averageAttempts, is: .optional, ofType: .double),
      .field(homeworkAnalytics.multipleAttemptsCount, is: .optional, ofType: .int),
      .field(homeworkAnalytics.reviewedCount, is: .required, ofType: .int),
      .field(homeworkAnalytics.pendingReviewCount, is: .required, ofType: .int),
      .field(homeworkAnalytics.commonMistakes, is: .optional, ofType: .string),
      .field(homeworkAnalytics.strugglingStudents, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(homeworkAnalytics.lastUpdatedAt, is: .required, ofType: .dateTime),
      .field(homeworkAnalytics.lastCalculatedAt, is: .optional, ofType: .dateTime),
      .field(homeworkAnalytics.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(homeworkAnalytics.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension HomeworkAnalytics: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}