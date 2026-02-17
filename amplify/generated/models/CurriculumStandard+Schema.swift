// swiftlint:disable all
import Amplify
import Foundation

extension CurriculumStandard {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case country
    case curriculumName
    case curriculumVersion
    case gradeLevel
    case gradeLevelCode
    case strand
    case strandCode
    case subStrand
    case subStrandCode
    case topicNumber
    case topicTitle
    case subTopicCode
    case subTopicDescription
    case curriculumCode
    case keywords
    case sequenceOrder
    case prerequisiteCodes
    case bulletPoints
    case notes
    case isActive
    case effectiveFrom
    case effectiveUntil
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let curriculumStandard = CurriculumStandard.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.read])
    ]
    
    model.listPluralName = "CurriculumStandards"
    model.syncPluralName = "CurriculumStandards"
    
    model.attributes(
      .index(fields: ["curriculumCode"], name: "byCurriculumCode"),
      .primaryKey(fields: [curriculumStandard.id])
    )
    
    model.fields(
      .field(curriculumStandard.id, is: .required, ofType: .string),
      .field(curriculumStandard.country, is: .required, ofType: .string),
      .field(curriculumStandard.curriculumName, is: .required, ofType: .string),
      .field(curriculumStandard.curriculumVersion, is: .required, ofType: .string),
      .field(curriculumStandard.gradeLevel, is: .required, ofType: .string),
      .field(curriculumStandard.gradeLevelCode, is: .required, ofType: .string),
      .field(curriculumStandard.strand, is: .required, ofType: .string),
      .field(curriculumStandard.strandCode, is: .required, ofType: .string),
      .field(curriculumStandard.subStrand, is: .required, ofType: .string),
      .field(curriculumStandard.subStrandCode, is: .required, ofType: .string),
      .field(curriculumStandard.topicNumber, is: .required, ofType: .string),
      .field(curriculumStandard.topicTitle, is: .required, ofType: .string),
      .field(curriculumStandard.subTopicCode, is: .required, ofType: .string),
      .field(curriculumStandard.subTopicDescription, is: .required, ofType: .string),
      .field(curriculumStandard.curriculumCode, is: .required, ofType: .string),
      .field(curriculumStandard.keywords, is: .required, ofType: .embeddedCollection(of: String.self)),
      .field(curriculumStandard.sequenceOrder, is: .required, ofType: .int),
      .field(curriculumStandard.prerequisiteCodes, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(curriculumStandard.bulletPoints, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(curriculumStandard.notes, is: .optional, ofType: .string),
      .field(curriculumStandard.isActive, is: .required, ofType: .bool),
      .field(curriculumStandard.effectiveFrom, is: .optional, ofType: .string),
      .field(curriculumStandard.effectiveUntil, is: .optional, ofType: .string),
      .field(curriculumStandard.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(curriculumStandard.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension CurriculumStandard: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}