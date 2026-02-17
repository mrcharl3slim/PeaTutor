// swiftlint:disable all
import Amplify
import Foundation

public struct StudentCurriculumProgress: Model {
  public let id: String
  public var studentId: String
  public var classroomId: String?
  public var country: String
  public var curriculumVersion: String
  public var gradeLevel: String
  public var gradeLevelCode: String
  public var totalTopicsInGrade: Int
  public var topicsAttempted: Int
  public var topicsMastered: Int
  public var topicsInProgress: Int
  public var topicsNotStarted: Int
  public var coveragePercentage: Double
  public var masteryPercentage: Double
  public var strandProgress: String
  public var masteredTopicCodes: [String]
  public var inProgressTopicCodes: [String]
  public var notStartedTopicCodes: [String]
  public var prerequisiteGaps: [String?]?
  public var recommendedNextTopics: [String?]?
  public var lastCalculatedAt: Temporal.DateTime
  public var lastUpdatedAt: Temporal.DateTime
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      studentId: String,
      classroomId: String? = nil,
      country: String,
      curriculumVersion: String,
      gradeLevel: String,
      gradeLevelCode: String,
      totalTopicsInGrade: Int,
      topicsAttempted: Int,
      topicsMastered: Int,
      topicsInProgress: Int,
      topicsNotStarted: Int,
      coveragePercentage: Double,
      masteryPercentage: Double,
      strandProgress: String,
      masteredTopicCodes: [String] = [],
      inProgressTopicCodes: [String] = [],
      notStartedTopicCodes: [String] = [],
      prerequisiteGaps: [String?]? = nil,
      recommendedNextTopics: [String?]? = nil,
      lastCalculatedAt: Temporal.DateTime,
      lastUpdatedAt: Temporal.DateTime) {
    self.init(id: id,
      studentId: studentId,
      classroomId: classroomId,
      country: country,
      curriculumVersion: curriculumVersion,
      gradeLevel: gradeLevel,
      gradeLevelCode: gradeLevelCode,
      totalTopicsInGrade: totalTopicsInGrade,
      topicsAttempted: topicsAttempted,
      topicsMastered: topicsMastered,
      topicsInProgress: topicsInProgress,
      topicsNotStarted: topicsNotStarted,
      coveragePercentage: coveragePercentage,
      masteryPercentage: masteryPercentage,
      strandProgress: strandProgress,
      masteredTopicCodes: masteredTopicCodes,
      inProgressTopicCodes: inProgressTopicCodes,
      notStartedTopicCodes: notStartedTopicCodes,
      prerequisiteGaps: prerequisiteGaps,
      recommendedNextTopics: recommendedNextTopics,
      lastCalculatedAt: lastCalculatedAt,
      lastUpdatedAt: lastUpdatedAt,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      studentId: String,
      classroomId: String? = nil,
      country: String,
      curriculumVersion: String,
      gradeLevel: String,
      gradeLevelCode: String,
      totalTopicsInGrade: Int,
      topicsAttempted: Int,
      topicsMastered: Int,
      topicsInProgress: Int,
      topicsNotStarted: Int,
      coveragePercentage: Double,
      masteryPercentage: Double,
      strandProgress: String,
      masteredTopicCodes: [String] = [],
      inProgressTopicCodes: [String] = [],
      notStartedTopicCodes: [String] = [],
      prerequisiteGaps: [String?]? = nil,
      recommendedNextTopics: [String?]? = nil,
      lastCalculatedAt: Temporal.DateTime,
      lastUpdatedAt: Temporal.DateTime,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.studentId = studentId
      self.classroomId = classroomId
      self.country = country
      self.curriculumVersion = curriculumVersion
      self.gradeLevel = gradeLevel
      self.gradeLevelCode = gradeLevelCode
      self.totalTopicsInGrade = totalTopicsInGrade
      self.topicsAttempted = topicsAttempted
      self.topicsMastered = topicsMastered
      self.topicsInProgress = topicsInProgress
      self.topicsNotStarted = topicsNotStarted
      self.coveragePercentage = coveragePercentage
      self.masteryPercentage = masteryPercentage
      self.strandProgress = strandProgress
      self.masteredTopicCodes = masteredTopicCodes
      self.inProgressTopicCodes = inProgressTopicCodes
      self.notStartedTopicCodes = notStartedTopicCodes
      self.prerequisiteGaps = prerequisiteGaps
      self.recommendedNextTopics = recommendedNextTopics
      self.lastCalculatedAt = lastCalculatedAt
      self.lastUpdatedAt = lastUpdatedAt
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}