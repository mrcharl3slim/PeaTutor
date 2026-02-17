// swiftlint:disable all
import Amplify
import Foundation

extension ClassroomMembership {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case studentId
    case status
    case enrolledAt
    case approvedAt
    case approvedBy
    case classroom
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let classroomMembership = ClassroomMembership.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "studentId", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .read, .update, .delete]),
      rule(allow: .private, operations: [.read])
    ]
    
    model.listPluralName = "ClassroomMemberships"
    model.syncPluralName = "ClassroomMemberships"
    
    model.attributes(
      .index(fields: ["classroomId", "enrolledAt"], name: "byClassroom"),
      .index(fields: ["studentId", "enrolledAt"], name: "byStudent"),
      .primaryKey(fields: [classroomMembership.id])
    )
    
    model.fields(
      .field(classroomMembership.id, is: .required, ofType: .string),
      .field(classroomMembership.studentId, is: .required, ofType: .string),
      .field(classroomMembership.status, is: .required, ofType: .enum(type: MembershipStatus.self)),
      .field(classroomMembership.enrolledAt, is: .required, ofType: .dateTime),
      .field(classroomMembership.approvedAt, is: .optional, ofType: .dateTime),
      .field(classroomMembership.approvedBy, is: .optional, ofType: .string),
      .belongsTo(classroomMembership.classroom, is: .optional, ofType: Classroom.self, targetNames: ["classroomId"]),
      .field(classroomMembership.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(classroomMembership.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension ClassroomMembership: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}