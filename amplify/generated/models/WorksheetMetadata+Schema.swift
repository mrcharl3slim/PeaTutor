// swiftlint:disable all
import Amplify
import Foundation

extension WorksheetMetadata {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case userId
    case topics
    case difficulty
    case cognitiveSkills
    case questionTypes
    case estimatedTimeMinutes
    case complexityLevel
    case commonCoreStandards
    case bloomsTaxonomyLevels
    case worksheet
    case curriculumCountry
    case curriculumVersion
    case moeCurriculumCodes
    case detectedGradeLevel
    case detectedGradeLevelCode
    case curriculumStrand
    case curriculumSubStrand
    case curriculumConfidence
    case curriculumMappedAt
    case extractedAt
    case aiModel
    case tokensUsed
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let worksheetMetadata = WorksheetMetadata.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .private, operations: [.read])
    ]
    
    model.listPluralName = "WorksheetMetadata"
    model.syncPluralName = "WorksheetMetadata"
    
    model.attributes(
      .index(fields: ["worksheetId"], name: "byWorksheet"),
      .primaryKey(fields: [worksheetMetadata.id])
    )
    
    model.fields(
      .field(worksheetMetadata.id, is: .required, ofType: .string),
      .field(worksheetMetadata.userId, is: .required, ofType: .string),
      .field(worksheetMetadata.topics, is: .required, ofType: .embeddedCollection(of: String.self)),
      .field(worksheetMetadata.difficulty, is: .required, ofType: .string),
      .field(worksheetMetadata.cognitiveSkills, is: .required, ofType: .embeddedCollection(of: String.self)),
      .field(worksheetMetadata.questionTypes, is: .required, ofType: .embeddedCollection(of: String.self)),
      .field(worksheetMetadata.estimatedTimeMinutes, is: .optional, ofType: .int),
      .field(worksheetMetadata.complexityLevel, is: .optional, ofType: .string),
      .field(worksheetMetadata.commonCoreStandards, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(worksheetMetadata.bloomsTaxonomyLevels, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .belongsTo(worksheetMetadata.worksheet, is: .optional, ofType: Worksheet.self, targetNames: ["worksheetId"]),
      .field(worksheetMetadata.curriculumCountry, is: .optional, ofType: .string),
      .field(worksheetMetadata.curriculumVersion, is: .optional, ofType: .string),
      .field(worksheetMetadata.moeCurriculumCodes, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(worksheetMetadata.detectedGradeLevel, is: .optional, ofType: .string),
      .field(worksheetMetadata.detectedGradeLevelCode, is: .optional, ofType: .string),
      .field(worksheetMetadata.curriculumStrand, is: .optional, ofType: .string),
      .field(worksheetMetadata.curriculumSubStrand, is: .optional, ofType: .string),
      .field(worksheetMetadata.curriculumConfidence, is: .optional, ofType: .double),
      .field(worksheetMetadata.curriculumMappedAt, is: .optional, ofType: .dateTime),
      .field(worksheetMetadata.extractedAt, is: .required, ofType: .dateTime),
      .field(worksheetMetadata.aiModel, is: .required, ofType: .string),
      .field(worksheetMetadata.tokensUsed, is: .optional, ofType: .int),
      .field(worksheetMetadata.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(worksheetMetadata.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension WorksheetMetadata: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}