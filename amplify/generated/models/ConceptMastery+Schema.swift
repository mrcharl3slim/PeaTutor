// swiftlint:disable all
import Amplify
import Foundation

extension ConceptMastery {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case studentId
    case classroomId
    case concept
    case gradeLevel
    case masteryPercentage
    case accuracyRate
    case totalAttempts
    case correctAttempts
    case incorrectAttempts
    case trend
    case recentQuestions
    case lastPracticed
    case easyQuestions
    case mediumQuestions
    case hardQuestions
    case easyCorrect
    case mediumCorrect
    case hardCorrect
    case strengthAreas
    case improvementAreas
    case recommendedPractice
    case curriculumCode
    case curriculumStrand
    case curriculumSubStrand
    case curriculumTopicTitle
    case prerequisitesMastered
    case prerequisiteGaps
    case curriculumMappedAt
    case calculatedAt
    case lastUpdatedAt
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let conceptMastery = ConceptMastery.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "studentId", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .private, operations: [.read])
    ]
    
    model.listPluralName = "ConceptMasteries"
    model.syncPluralName = "ConceptMasteries"
    
    model.attributes(
      .index(fields: ["studentId", "concept"], name: "byStudent"),
      .index(fields: ["classroomId"], name: "byClassroom"),
      .index(fields: ["curriculumCode"], name: "byCurriculumCode"),
      .primaryKey(fields: [conceptMastery.id])
    )
    
    model.fields(
      .field(conceptMastery.id, is: .required, ofType: .string),
      .field(conceptMastery.studentId, is: .required, ofType: .string),
      .field(conceptMastery.classroomId, is: .optional, ofType: .string),
      .field(conceptMastery.concept, is: .required, ofType: .string),
      .field(conceptMastery.gradeLevel, is: .optional, ofType: .string),
      .field(conceptMastery.masteryPercentage, is: .required, ofType: .double),
      .field(conceptMastery.accuracyRate, is: .required, ofType: .double),
      .field(conceptMastery.totalAttempts, is: .required, ofType: .int),
      .field(conceptMastery.correctAttempts, is: .required, ofType: .int),
      .field(conceptMastery.incorrectAttempts, is: .required, ofType: .int),
      .field(conceptMastery.trend, is: .required, ofType: .string),
      .field(conceptMastery.recentQuestions, is: .required, ofType: .int),
      .field(conceptMastery.lastPracticed, is: .optional, ofType: .dateTime),
      .field(conceptMastery.easyQuestions, is: .required, ofType: .int),
      .field(conceptMastery.mediumQuestions, is: .required, ofType: .int),
      .field(conceptMastery.hardQuestions, is: .required, ofType: .int),
      .field(conceptMastery.easyCorrect, is: .required, ofType: .int),
      .field(conceptMastery.mediumCorrect, is: .required, ofType: .int),
      .field(conceptMastery.hardCorrect, is: .required, ofType: .int),
      .field(conceptMastery.strengthAreas, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(conceptMastery.improvementAreas, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(conceptMastery.recommendedPractice, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(conceptMastery.curriculumCode, is: .optional, ofType: .string),
      .field(conceptMastery.curriculumStrand, is: .optional, ofType: .string),
      .field(conceptMastery.curriculumSubStrand, is: .optional, ofType: .string),
      .field(conceptMastery.curriculumTopicTitle, is: .optional, ofType: .string),
      .field(conceptMastery.prerequisitesMastered, is: .optional, ofType: .bool),
      .field(conceptMastery.prerequisiteGaps, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(conceptMastery.curriculumMappedAt, is: .optional, ofType: .dateTime),
      .field(conceptMastery.calculatedAt, is: .required, ofType: .dateTime),
      .field(conceptMastery.lastUpdatedAt, is: .required, ofType: .dateTime),
      .field(conceptMastery.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(conceptMastery.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension ConceptMastery: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}