// swiftlint:disable all
import Amplify
import Foundation

extension StudentAnalyticsSummary {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case studentId
    case classroomId
    case overallProgress
    case totalQuestionsAttempted
    case totalQuestionsCorrect
    case overallAccuracy
    case masteredConcepts
    case developingConcepts
    case needsWorkConcepts
    case topStrengths
    case topWeaknesses
    case mostCommonErrors
    case highSeverityErrorCount
    case mediumSeverityErrorCount
    case currentStreak
    case longestStreak
    case practiceFrequency
    case computationScore
    case problemSolvingScore
    case reasoningScore
    case accuracyScore
    case wordProblemScore
    case lastCalculated
    case lastUpdated
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let studentAnalyticsSummary = StudentAnalyticsSummary.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "studentId", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .private, operations: [.read])
    ]
    
    model.listPluralName = "StudentAnalyticsSummaries"
    model.syncPluralName = "StudentAnalyticsSummaries"
    
    model.attributes(
      .index(fields: ["studentId"], name: "byStudent"),
      .index(fields: ["classroomId"], name: "byClassroom"),
      .primaryKey(fields: [studentAnalyticsSummary.id])
    )
    
    model.fields(
      .field(studentAnalyticsSummary.id, is: .required, ofType: .string),
      .field(studentAnalyticsSummary.studentId, is: .required, ofType: .string),
      .field(studentAnalyticsSummary.classroomId, is: .optional, ofType: .string),
      .field(studentAnalyticsSummary.overallProgress, is: .required, ofType: .double),
      .field(studentAnalyticsSummary.totalQuestionsAttempted, is: .required, ofType: .int),
      .field(studentAnalyticsSummary.totalQuestionsCorrect, is: .required, ofType: .int),
      .field(studentAnalyticsSummary.overallAccuracy, is: .required, ofType: .double),
      .field(studentAnalyticsSummary.masteredConcepts, is: .required, ofType: .embeddedCollection(of: String.self)),
      .field(studentAnalyticsSummary.developingConcepts, is: .required, ofType: .embeddedCollection(of: String.self)),
      .field(studentAnalyticsSummary.needsWorkConcepts, is: .required, ofType: .embeddedCollection(of: String.self)),
      .field(studentAnalyticsSummary.topStrengths, is: .required, ofType: .embeddedCollection(of: String.self)),
      .field(studentAnalyticsSummary.topWeaknesses, is: .required, ofType: .embeddedCollection(of: String.self)),
      .field(studentAnalyticsSummary.mostCommonErrors, is: .required, ofType: .embeddedCollection(of: String.self)),
      .field(studentAnalyticsSummary.highSeverityErrorCount, is: .required, ofType: .int),
      .field(studentAnalyticsSummary.mediumSeverityErrorCount, is: .required, ofType: .int),
      .field(studentAnalyticsSummary.currentStreak, is: .required, ofType: .int),
      .field(studentAnalyticsSummary.longestStreak, is: .required, ofType: .int),
      .field(studentAnalyticsSummary.practiceFrequency, is: .required, ofType: .string),
      .field(studentAnalyticsSummary.computationScore, is: .required, ofType: .double),
      .field(studentAnalyticsSummary.problemSolvingScore, is: .required, ofType: .double),
      .field(studentAnalyticsSummary.reasoningScore, is: .required, ofType: .double),
      .field(studentAnalyticsSummary.accuracyScore, is: .required, ofType: .double),
      .field(studentAnalyticsSummary.wordProblemScore, is: .required, ofType: .double),
      .field(studentAnalyticsSummary.lastCalculated, is: .required, ofType: .dateTime),
      .field(studentAnalyticsSummary.lastUpdated, is: .required, ofType: .dateTime),
      .field(studentAnalyticsSummary.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(studentAnalyticsSummary.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension StudentAnalyticsSummary: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}