// swiftlint:disable all
import Amplify
import Foundation

extension UserProfile {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case userId
    case email
    case userRole
    case displayName
    case schoolName
    case gradeLevel
    case profileImageUrl
    case onboardingCompleted
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let userProfile = UserProfile.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "userId", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .private, operations: [.read])
    ]
    
    model.listPluralName = "UserProfiles"
    model.syncPluralName = "UserProfiles"
    
    model.attributes(
      .index(fields: ["userId"], name: "byUserId"),
      .primaryKey(fields: [userProfile.id])
    )
    
    model.fields(
      .field(userProfile.id, is: .required, ofType: .string),
      .field(userProfile.userId, is: .required, ofType: .string),
      .field(userProfile.email, is: .required, ofType: .string),
      .field(userProfile.userRole, is: .required, ofType: .enum(type: UserRole.self)),
      .field(userProfile.displayName, is: .required, ofType: .string),
      .field(userProfile.schoolName, is: .optional, ofType: .string),
      .field(userProfile.gradeLevel, is: .optional, ofType: .string),
      .field(userProfile.profileImageUrl, is: .optional, ofType: .string),
      .field(userProfile.onboardingCompleted, is: .required, ofType: .bool),
      .field(userProfile.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(userProfile.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension UserProfile: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}