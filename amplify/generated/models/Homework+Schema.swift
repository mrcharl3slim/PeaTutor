// swiftlint:disable all
import Amplify
import Foundation

extension Homework {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case teacherId
    case title
    case description
    case dueDate
    case assignedDate
    case totalPoints
    case isPublished
    case worksheet
    case instructions
    case learningObjectives
    case allowLateSubmissions
    case allowMultipleAttempts
    case maxAttempts
    case classroom
    case submissions
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let homework = Homework.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "teacherId", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .private, operations: [.read])
    ]
    
    model.listPluralName = "Homework"
    model.syncPluralName = "Homework"
    
    model.attributes(
      .index(fields: ["classroomId", "dueDate"], name: "byClassroom"),
      .index(fields: ["worksheetId"], name: "byWorksheet"),
      .primaryKey(fields: [homework.id])
    )
    
    model.fields(
      .field(homework.id, is: .required, ofType: .string),
      .field(homework.teacherId, is: .required, ofType: .string),
      .field(homework.title, is: .required, ofType: .string),
      .field(homework.description, is: .optional, ofType: .string),
      .field(homework.dueDate, is: .required, ofType: .dateTime),
      .field(homework.assignedDate, is: .required, ofType: .dateTime),
      .field(homework.totalPoints, is: .optional, ofType: .int),
      .field(homework.isPublished, is: .required, ofType: .bool),
      .belongsTo(homework.worksheet, is: .optional, ofType: Worksheet.self, targetNames: ["worksheetId"]),
      .field(homework.instructions, is: .optional, ofType: .string),
      .field(homework.learningObjectives, is: .optional, ofType: .string),
      .field(homework.allowLateSubmissions, is: .optional, ofType: .bool),
      .field(homework.allowMultipleAttempts, is: .optional, ofType: .bool),
      .field(homework.maxAttempts, is: .optional, ofType: .int),
      .belongsTo(homework.classroom, is: .optional, ofType: Classroom.self, targetNames: ["classroomId"]),
      .hasMany(homework.submissions, is: .optional, ofType: FullWorksheetSolution.self, associatedWith: FullWorksheetSolution.keys.homework),
      .field(homework.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(homework.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Homework: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}