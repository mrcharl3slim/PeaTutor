// swiftlint:disable all
import Amplify
import Foundation

extension StudentCurriculumProgress {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case studentId
    case classroomId
    case country
    case curriculumVersion
    case gradeLevel
    case gradeLevelCode
    case totalTopicsInGrade
    case topicsAttempted
    case topicsMastered
    case topicsInProgress
    case topicsNotStarted
    case coveragePercentage
    case masteryPercentage
    case strandProgress
    case masteredTopicCodes
    case inProgressTopicCodes
    case notStartedTopicCodes
    case prerequisiteGaps
    case recommendedNextTopics
    case lastCalculatedAt
    case lastUpdatedAt
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let studentCurriculumProgress = StudentCurriculumProgress.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "studentId", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .private, operations: [.read])
    ]
    
    model.listPluralName = "StudentCurriculumProgresses"
    model.syncPluralName = "StudentCurriculumProgresses"
    
    model.attributes(
      .index(fields: ["studentId", "gradeLevel"], name: "byStudent"),
      .index(fields: ["classroomId"], name: "byClassroom"),
      .primaryKey(fields: [studentCurriculumProgress.id])
    )
    
    model.fields(
      .field(studentCurriculumProgress.id, is: .required, ofType: .string),
      .field(studentCurriculumProgress.studentId, is: .required, ofType: .string),
      .field(studentCurriculumProgress.classroomId, is: .optional, ofType: .string),
      .field(studentCurriculumProgress.country, is: .required, ofType: .string),
      .field(studentCurriculumProgress.curriculumVersion, is: .required, ofType: .string),
      .field(studentCurriculumProgress.gradeLevel, is: .required, ofType: .string),
      .field(studentCurriculumProgress.gradeLevelCode, is: .required, ofType: .string),
      .field(studentCurriculumProgress.totalTopicsInGrade, is: .required, ofType: .int),
      .field(studentCurriculumProgress.topicsAttempted, is: .required, ofType: .int),
      .field(studentCurriculumProgress.topicsMastered, is: .required, ofType: .int),
      .field(studentCurriculumProgress.topicsInProgress, is: .required, ofType: .int),
      .field(studentCurriculumProgress.topicsNotStarted, is: .required, ofType: .int),
      .field(studentCurriculumProgress.coveragePercentage, is: .required, ofType: .double),
      .field(studentCurriculumProgress.masteryPercentage, is: .required, ofType: .double),
      .field(studentCurriculumProgress.strandProgress, is: .required, ofType: .string),
      .field(studentCurriculumProgress.masteredTopicCodes, is: .required, ofType: .embeddedCollection(of: String.self)),
      .field(studentCurriculumProgress.inProgressTopicCodes, is: .required, ofType: .embeddedCollection(of: String.self)),
      .field(studentCurriculumProgress.notStartedTopicCodes, is: .required, ofType: .embeddedCollection(of: String.self)),
      .field(studentCurriculumProgress.prerequisiteGaps, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(studentCurriculumProgress.recommendedNextTopics, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(studentCurriculumProgress.lastCalculatedAt, is: .required, ofType: .dateTime),
      .field(studentCurriculumProgress.lastUpdatedAt, is: .required, ofType: .dateTime),
      .field(studentCurriculumProgress.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(studentCurriculumProgress.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension StudentCurriculumProgress: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}