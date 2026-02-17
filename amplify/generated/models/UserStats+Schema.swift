// swiftlint:disable all
import Amplify
import Foundation

extension UserStats {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case userId
    case userRole
    case totalWorksheets
    case totalQuestions
    case totalSolutionsSubmitted
    case totalFeedbackReceived
    case averageScore
    case correctAnswersCount
    case totalAttemptsCount
    case lastActiveAt
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let userStats = UserStats.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "UserStats"
    model.syncPluralName = "UserStats"
    
    model.attributes(
      .primaryKey(fields: [userStats.id])
    )
    
    model.fields(
      .field(userStats.id, is: .required, ofType: .string),
      .field(userStats.userId, is: .required, ofType: .string),
      .field(userStats.userRole, is: .optional, ofType: .enum(type: UserRole.self)),
      .field(userStats.totalWorksheets, is: .required, ofType: .int),
      .field(userStats.totalQuestions, is: .required, ofType: .int),
      .field(userStats.totalSolutionsSubmitted, is: .required, ofType: .int),
      .field(userStats.totalFeedbackReceived, is: .required, ofType: .int),
      .field(userStats.averageScore, is: .optional, ofType: .double),
      .field(userStats.correctAnswersCount, is: .required, ofType: .int),
      .field(userStats.totalAttemptsCount, is: .required, ofType: .int),
      .field(userStats.lastActiveAt, is: .optional, ofType: .dateTime),
      .field(userStats.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(userStats.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension UserStats: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}