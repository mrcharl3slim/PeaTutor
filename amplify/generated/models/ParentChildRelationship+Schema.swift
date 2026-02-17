// swiftlint:disable all
import Amplify
import Foundation

extension ParentChildRelationship {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case parentId
    case childId
    case linkingCode
    case relationshipType
    case status
    case approvedAt
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let parentChildRelationship = ParentChildRelationship.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "childId", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .private, operations: [.read, .update])
    ]
    
    model.listPluralName = "ParentChildRelationships"
    model.syncPluralName = "ParentChildRelationships"
    
    model.attributes(
      .index(fields: ["parentId", "id"], name: "byParent"),
      .index(fields: ["childId", "id"], name: "byChild"),
      .index(fields: ["linkingCode"], name: "byLinkingCode"),
      .primaryKey(fields: [parentChildRelationship.id])
    )
    
    model.fields(
      .field(parentChildRelationship.id, is: .required, ofType: .string),
      .field(parentChildRelationship.parentId, is: .required, ofType: .string),
      .field(parentChildRelationship.childId, is: .required, ofType: .string),
      .field(parentChildRelationship.linkingCode, is: .required, ofType: .string),
      .field(parentChildRelationship.relationshipType, is: .required, ofType: .enum(type: RelationshipType.self)),
      .field(parentChildRelationship.status, is: .required, ofType: .enum(type: LinkStatus.self)),
      .field(parentChildRelationship.approvedAt, is: .optional, ofType: .dateTime),
      .field(parentChildRelationship.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(parentChildRelationship.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension ParentChildRelationship: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}