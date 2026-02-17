// swiftlint:disable all
import Amplify
import Foundation

extension StudentProgress {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case studentId
    case classroom
    case totalHomeworkAssigned
    case totalHomeworkCompleted
    case totalHomeworkLate
    case totalSubmissions
    case averageAttemptsPerHomework
    case currentStreak
    case longestStreak
    case skillsBreakdown
    case strengthAreas
    case improvementAreas
    case lastSubmissionAt
    case progressUpdatedAt
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let studentProgress = StudentProgress.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "studentId", identityClaim: "cognito:username", provider: .userPools, operations: [.read, .create, .update, .delete]),
      rule(allow: .private, operations: [.read])
    ]
    
    model.listPluralName = "StudentProgresses"
    model.syncPluralName = "StudentProgresses"
    
    model.attributes(
      .index(fields: ["studentId"], name: "byStudent"),
      .index(fields: ["classroomId"], name: "byClassroom"),
      .primaryKey(fields: [studentProgress.id])
    )
    
    model.fields(
      .field(studentProgress.id, is: .required, ofType: .string),
      .field(studentProgress.studentId, is: .required, ofType: .string),
      .belongsTo(studentProgress.classroom, is: .optional, ofType: Classroom.self, targetNames: ["classroomId"]),
      .field(studentProgress.totalHomeworkAssigned, is: .required, ofType: .int),
      .field(studentProgress.totalHomeworkCompleted, is: .required, ofType: .int),
      .field(studentProgress.totalHomeworkLate, is: .required, ofType: .int),
      .field(studentProgress.totalSubmissions, is: .required, ofType: .int),
      .field(studentProgress.averageAttemptsPerHomework, is: .optional, ofType: .double),
      .field(studentProgress.currentStreak, is: .optional, ofType: .int),
      .field(studentProgress.longestStreak, is: .optional, ofType: .int),
      .field(studentProgress.skillsBreakdown, is: .optional, ofType: .string),
      .field(studentProgress.strengthAreas, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(studentProgress.improvementAreas, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(studentProgress.lastSubmissionAt, is: .optional, ofType: .dateTime),
      .field(studentProgress.progressUpdatedAt, is: .optional, ofType: .dateTime),
      .field(studentProgress.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(studentProgress.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension StudentProgress: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}