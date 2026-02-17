// swiftlint:disable all
import Amplify
import Foundation

extension HomeworkSubmission {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case studentId
    case status
    case submittedAt
    case worksheetId
    case score
    case feedback
    case reviewedBy
    case reviewedAt
    case homework
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let homeworkSubmission = HomeworkSubmission.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "studentId", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .read]),
      rule(allow: .private, operations: [.read])
    ]
    
    model.listPluralName = "HomeworkSubmissions"
    model.syncPluralName = "HomeworkSubmissions"
    
    model.attributes(
      .index(fields: ["homeworkId", "submittedAt"], name: "byHomework"),
      .index(fields: ["studentId", "submittedAt"], name: "byStudent"),
      .primaryKey(fields: [homeworkSubmission.id])
    )
    
    model.fields(
      .field(homeworkSubmission.id, is: .required, ofType: .string),
      .field(homeworkSubmission.studentId, is: .required, ofType: .string),
      .field(homeworkSubmission.status, is: .required, ofType: .enum(type: SubmissionStatus.self)),
      .field(homeworkSubmission.submittedAt, is: .optional, ofType: .dateTime),
      .field(homeworkSubmission.worksheetId, is: .optional, ofType: .string),
      .field(homeworkSubmission.score, is: .optional, ofType: .int),
      .field(homeworkSubmission.feedback, is: .optional, ofType: .string),
      .field(homeworkSubmission.reviewedBy, is: .optional, ofType: .string),
      .field(homeworkSubmission.reviewedAt, is: .optional, ofType: .dateTime),
      .belongsTo(homeworkSubmission.homework, is: .optional, ofType: Homework.self, targetNames: ["homeworkId"]),
      .field(homeworkSubmission.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(homeworkSubmission.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension HomeworkSubmission: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}