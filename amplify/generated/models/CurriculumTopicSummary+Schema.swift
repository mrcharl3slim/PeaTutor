// swiftlint:disable all
import Amplify
import Foundation

extension CurriculumTopicSummary {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case country
    case curriculumVersion
    case gradeLevel
    case gradeLevelCode
    case strand
    case strandCode
    case subStrand
    case subStrandCode
    case topicNumber
    case topicTitle
    case topicCode
    case subTopicCount
    case subTopicCodes
    case allKeywords
    case sequenceOrder
    case isActive
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let curriculumTopicSummary = CurriculumTopicSummary.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.read])
    ]
    
    model.listPluralName = "CurriculumTopicSummaries"
    model.syncPluralName = "CurriculumTopicSummaries"
    
    model.attributes(
      .index(fields: ["topicCode"], name: "byTopicCode"),
      .primaryKey(fields: [curriculumTopicSummary.id])
    )
    
    model.fields(
      .field(curriculumTopicSummary.id, is: .required, ofType: .string),
      .field(curriculumTopicSummary.country, is: .required, ofType: .string),
      .field(curriculumTopicSummary.curriculumVersion, is: .required, ofType: .string),
      .field(curriculumTopicSummary.gradeLevel, is: .required, ofType: .string),
      .field(curriculumTopicSummary.gradeLevelCode, is: .required, ofType: .string),
      .field(curriculumTopicSummary.strand, is: .required, ofType: .string),
      .field(curriculumTopicSummary.strandCode, is: .required, ofType: .string),
      .field(curriculumTopicSummary.subStrand, is: .required, ofType: .string),
      .field(curriculumTopicSummary.subStrandCode, is: .required, ofType: .string),
      .field(curriculumTopicSummary.topicNumber, is: .required, ofType: .string),
      .field(curriculumTopicSummary.topicTitle, is: .required, ofType: .string),
      .field(curriculumTopicSummary.topicCode, is: .required, ofType: .string),
      .field(curriculumTopicSummary.subTopicCount, is: .required, ofType: .int),
      .field(curriculumTopicSummary.subTopicCodes, is: .required, ofType: .embeddedCollection(of: String.self)),
      .field(curriculumTopicSummary.allKeywords, is: .required, ofType: .embeddedCollection(of: String.self)),
      .field(curriculumTopicSummary.sequenceOrder, is: .required, ofType: .int),
      .field(curriculumTopicSummary.isActive, is: .required, ofType: .bool),
      .field(curriculumTopicSummary.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(curriculumTopicSummary.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension CurriculumTopicSummary: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}