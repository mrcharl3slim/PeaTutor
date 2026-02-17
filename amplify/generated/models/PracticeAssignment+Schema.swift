// swiftlint:disable all
import Amplify
import Foundation

extension PracticeAssignment {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case assignedByUserId
    case assignedByRole
    case studentId
    case classroomId
    case title
    case description
    case dueDate
    case assignedDate
    case problemIds
    case problemCount
    case curriculumCodes
    case curriculumGradeLevel
    case targetConcepts
    case sourceType
    case status
    case startedAt
    case completedAt
    case correctCount
    case totalAttempted
    case score
    case timeSpentSeconds
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let practiceAssignment = PracticeAssignment.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "assignedByUserId", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .owner, ownerField: "studentId", identityClaim: "cognito:username", provider: .userPools, operations: [.read, .update]),
      rule(allow: .private, operations: [.read])
    ]
    
    model.listPluralName = "PracticeAssignments"
    model.syncPluralName = "PracticeAssignments"
    
    model.attributes(
      .index(fields: ["assignedByUserId", "assignedDate"], name: "byAssigner"),
      .index(fields: ["studentId", "status"], name: "byStudent"),
      .index(fields: ["classroomId", "assignedDate"], name: "byClassroom"),
      .primaryKey(fields: [practiceAssignment.id])
    )
    
    model.fields(
      .field(practiceAssignment.id, is: .required, ofType: .string),
      .field(practiceAssignment.assignedByUserId, is: .required, ofType: .string),
      .field(practiceAssignment.assignedByRole, is: .required, ofType: .string),
      .field(practiceAssignment.studentId, is: .required, ofType: .string),
      .field(practiceAssignment.classroomId, is: .optional, ofType: .string),
      .field(practiceAssignment.title, is: .required, ofType: .string),
      .field(practiceAssignment.description, is: .optional, ofType: .string),
      .field(practiceAssignment.dueDate, is: .optional, ofType: .dateTime),
      .field(practiceAssignment.assignedDate, is: .required, ofType: .dateTime),
      .field(practiceAssignment.problemIds, is: .required, ofType: .embeddedCollection(of: String.self)),
      .field(practiceAssignment.problemCount, is: .required, ofType: .int),
      .field(practiceAssignment.curriculumCodes, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(practiceAssignment.curriculumGradeLevel, is: .optional, ofType: .string),
      .field(practiceAssignment.targetConcepts, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(practiceAssignment.sourceType, is: .required, ofType: .string),
      .field(practiceAssignment.status, is: .required, ofType: .string),
      .field(practiceAssignment.startedAt, is: .optional, ofType: .dateTime),
      .field(practiceAssignment.completedAt, is: .optional, ofType: .dateTime),
      .field(practiceAssignment.correctCount, is: .optional, ofType: .int),
      .field(practiceAssignment.totalAttempted, is: .optional, ofType: .int),
      .field(practiceAssignment.score, is: .optional, ofType: .double),
      .field(practiceAssignment.timeSpentSeconds, is: .optional, ofType: .int),
      .field(practiceAssignment.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(practiceAssignment.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension PracticeAssignment: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}