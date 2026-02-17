// swiftlint:disable all
import Amplify
import Foundation

extension Classroom {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case teacherId
    case className
    case classCode
    case subject
    case description
    case gradeLevel
    case isActive
    case memberships
    case homework
    case studentProgress
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let classroom = Classroom.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "teacherId", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .private, operations: [.read])
    ]
    
    model.listPluralName = "Classrooms"
    model.syncPluralName = "Classrooms"
    
    model.attributes(
      .index(fields: ["teacherId", "id"], name: "byTeacher"),
      .index(fields: ["classCode"], name: "byClassCode"),
      .primaryKey(fields: [classroom.id])
    )
    
    model.fields(
      .field(classroom.id, is: .required, ofType: .string),
      .field(classroom.teacherId, is: .required, ofType: .string),
      .field(classroom.className, is: .required, ofType: .string),
      .field(classroom.classCode, is: .required, ofType: .string),
      .field(classroom.subject, is: .optional, ofType: .string),
      .field(classroom.description, is: .optional, ofType: .string),
      .field(classroom.gradeLevel, is: .optional, ofType: .string),
      .field(classroom.isActive, is: .required, ofType: .bool),
      .hasMany(classroom.memberships, is: .optional, ofType: ClassroomMembership.self, associatedWith: ClassroomMembership.keys.classroom),
      .hasMany(classroom.homework, is: .optional, ofType: Homework.self, associatedWith: Homework.keys.classroom),
      .hasMany(classroom.studentProgress, is: .optional, ofType: StudentProgress.self, associatedWith: StudentProgress.keys.classroom),
      .field(classroom.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(classroom.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Classroom: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}