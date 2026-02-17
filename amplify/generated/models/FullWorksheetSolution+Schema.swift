// swiftlint:disable all
import Amplify
import Foundation

extension FullWorksheetSolution {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case userId
    case s3SolutionImageKey
    case overallFeedback
    case overallScore
    case totalQuestions
    case completedQuestions
    case questionsWithIssues
    case suggestions
    case detailedFeedback
    case attemptNumber
    case submittedAt
    case worksheet
    case aiModel
    case tokensUsed
    case homework
    case isLate
    case teacherReviewed
    case teacherNotes
    case teacherReviewedAt
    case teacherReviewedBy
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let fullWorksheetSolution = FullWorksheetSolution.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .private, operations: [.read])
    ]
    
    model.listPluralName = "FullWorksheetSolutions"
    model.syncPluralName = "FullWorksheetSolutions"
    
    model.attributes(
      .index(fields: ["worksheetId", "submittedAt"], name: "byWorksheetSolutions"),
      .index(fields: ["homeworkId"], name: "byHomeworkSubmissions"),
      .primaryKey(fields: [fullWorksheetSolution.id])
    )
    
    model.fields(
      .field(fullWorksheetSolution.id, is: .required, ofType: .string),
      .field(fullWorksheetSolution.userId, is: .required, ofType: .string),
      .field(fullWorksheetSolution.s3SolutionImageKey, is: .required, ofType: .string),
      .field(fullWorksheetSolution.overallFeedback, is: .required, ofType: .string),
      .field(fullWorksheetSolution.overallScore, is: .required, ofType: .int),
      .field(fullWorksheetSolution.totalQuestions, is: .required, ofType: .int),
      .field(fullWorksheetSolution.completedQuestions, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(fullWorksheetSolution.questionsWithIssues, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(fullWorksheetSolution.suggestions, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(fullWorksheetSolution.detailedFeedback, is: .optional, ofType: .string),
      .field(fullWorksheetSolution.attemptNumber, is: .required, ofType: .int),
      .field(fullWorksheetSolution.submittedAt, is: .required, ofType: .dateTime),
      .belongsTo(fullWorksheetSolution.worksheet, is: .optional, ofType: Worksheet.self, targetNames: ["worksheetId"]),
      .field(fullWorksheetSolution.aiModel, is: .optional, ofType: .string),
      .field(fullWorksheetSolution.tokensUsed, is: .optional, ofType: .int),
      .belongsTo(fullWorksheetSolution.homework, is: .optional, ofType: Homework.self, targetNames: ["homeworkId"]),
      .field(fullWorksheetSolution.isLate, is: .optional, ofType: .bool),
      .field(fullWorksheetSolution.teacherReviewed, is: .optional, ofType: .bool),
      .field(fullWorksheetSolution.teacherNotes, is: .optional, ofType: .string),
      .field(fullWorksheetSolution.teacherReviewedAt, is: .optional, ofType: .dateTime),
      .field(fullWorksheetSolution.teacherReviewedBy, is: .optional, ofType: .string),
      .field(fullWorksheetSolution.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(fullWorksheetSolution.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension FullWorksheetSolution: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}