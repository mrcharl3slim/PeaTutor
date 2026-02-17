// swiftlint:disable all
import Amplify
import Foundation

extension Worksheet {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case userId
    case title
    case fileType
    case fileName
    case s3WorksheetKey
    case extractionResult
    case questionCount
    case totalMarks
    case uploadedAt
    case fileSize
    case contentHash
    case sourceFileHashes
    case lastAccessedAt
    case questions
    case fullWorksheetSolutions
    case homeworkAssignments
    case metadata
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let worksheet = Worksheet.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Worksheets"
    model.syncPluralName = "Worksheets"
    
    model.attributes(
      .primaryKey(fields: [worksheet.id])
    )
    
    model.fields(
      .field(worksheet.id, is: .required, ofType: .string),
      .field(worksheet.userId, is: .required, ofType: .string),
      .field(worksheet.title, is: .required, ofType: .string),
      .field(worksheet.fileType, is: .optional, ofType: .string),
      .field(worksheet.fileName, is: .required, ofType: .string),
      .field(worksheet.s3WorksheetKey, is: .required, ofType: .string),
      .field(worksheet.extractionResult, is: .optional, ofType: .string),
      .field(worksheet.questionCount, is: .optional, ofType: .int),
      .field(worksheet.totalMarks, is: .optional, ofType: .int),
      .field(worksheet.uploadedAt, is: .required, ofType: .dateTime),
      .field(worksheet.fileSize, is: .optional, ofType: .int),
      .field(worksheet.contentHash, is: .optional, ofType: .string),
      .field(worksheet.sourceFileHashes, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(worksheet.lastAccessedAt, is: .optional, ofType: .dateTime),
      .hasMany(worksheet.questions, is: .optional, ofType: Question.self, associatedWith: Question.keys.worksheet),
      .hasMany(worksheet.fullWorksheetSolutions, is: .optional, ofType: FullWorksheetSolution.self, associatedWith: FullWorksheetSolution.keys.worksheet),
      .hasMany(worksheet.homeworkAssignments, is: .optional, ofType: Homework.self, associatedWith: Homework.keys.worksheet),
      .hasMany(worksheet.metadata, is: .optional, ofType: WorksheetMetadata.self, associatedWith: WorksheetMetadata.keys.worksheet),
      .field(worksheet.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(worksheet.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Worksheet: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}