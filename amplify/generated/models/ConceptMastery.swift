// swiftlint:disable all
import Amplify
import Foundation

public struct ConceptMastery: Model {
  public let id: String
  public var studentId: String
  public var classroomId: String?
  public var concept: String
  public var gradeLevel: String?
  public var masteryPercentage: Double
  public var accuracyRate: Double
  public var totalAttempts: Int
  public var correctAttempts: Int
  public var incorrectAttempts: Int
  public var trend: String
  public var recentQuestions: Int
  public var lastPracticed: Temporal.DateTime?
  public var easyQuestions: Int
  public var mediumQuestions: Int
  public var hardQuestions: Int
  public var easyCorrect: Int
  public var mediumCorrect: Int
  public var hardCorrect: Int
  public var strengthAreas: [String?]?
  public var improvementAreas: [String?]?
  public var recommendedPractice: [String?]?
  public var curriculumCode: String?
  public var curriculumStrand: String?
  public var curriculumSubStrand: String?
  public var curriculumTopicTitle: String?
  public var prerequisitesMastered: Bool?
  public var prerequisiteGaps: [String?]?
  public var curriculumMappedAt: Temporal.DateTime?
  public var calculatedAt: Temporal.DateTime
  public var lastUpdatedAt: Temporal.DateTime
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      studentId: String,
      classroomId: String? = nil,
      concept: String,
      gradeLevel: String? = nil,
      masteryPercentage: Double,
      accuracyRate: Double,
      totalAttempts: Int,
      correctAttempts: Int,
      incorrectAttempts: Int,
      trend: String,
      recentQuestions: Int,
      lastPracticed: Temporal.DateTime? = nil,
      easyQuestions: Int,
      mediumQuestions: Int,
      hardQuestions: Int,
      easyCorrect: Int,
      mediumCorrect: Int,
      hardCorrect: Int,
      strengthAreas: [String?]? = nil,
      improvementAreas: [String?]? = nil,
      recommendedPractice: [String?]? = nil,
      curriculumCode: String? = nil,
      curriculumStrand: String? = nil,
      curriculumSubStrand: String? = nil,
      curriculumTopicTitle: String? = nil,
      prerequisitesMastered: Bool? = nil,
      prerequisiteGaps: [String?]? = nil,
      curriculumMappedAt: Temporal.DateTime? = nil,
      calculatedAt: Temporal.DateTime,
      lastUpdatedAt: Temporal.DateTime) {
    self.init(id: id,
      studentId: studentId,
      classroomId: classroomId,
      concept: concept,
      gradeLevel: gradeLevel,
      masteryPercentage: masteryPercentage,
      accuracyRate: accuracyRate,
      totalAttempts: totalAttempts,
      correctAttempts: correctAttempts,
      incorrectAttempts: incorrectAttempts,
      trend: trend,
      recentQuestions: recentQuestions,
      lastPracticed: lastPracticed,
      easyQuestions: easyQuestions,
      mediumQuestions: mediumQuestions,
      hardQuestions: hardQuestions,
      easyCorrect: easyCorrect,
      mediumCorrect: mediumCorrect,
      hardCorrect: hardCorrect,
      strengthAreas: strengthAreas,
      improvementAreas: improvementAreas,
      recommendedPractice: recommendedPractice,
      curriculumCode: curriculumCode,
      curriculumStrand: curriculumStrand,
      curriculumSubStrand: curriculumSubStrand,
      curriculumTopicTitle: curriculumTopicTitle,
      prerequisitesMastered: prerequisitesMastered,
      prerequisiteGaps: prerequisiteGaps,
      curriculumMappedAt: curriculumMappedAt,
      calculatedAt: calculatedAt,
      lastUpdatedAt: lastUpdatedAt,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      studentId: String,
      classroomId: String? = nil,
      concept: String,
      gradeLevel: String? = nil,
      masteryPercentage: Double,
      accuracyRate: Double,
      totalAttempts: Int,
      correctAttempts: Int,
      incorrectAttempts: Int,
      trend: String,
      recentQuestions: Int,
      lastPracticed: Temporal.DateTime? = nil,
      easyQuestions: Int,
      mediumQuestions: Int,
      hardQuestions: Int,
      easyCorrect: Int,
      mediumCorrect: Int,
      hardCorrect: Int,
      strengthAreas: [String?]? = nil,
      improvementAreas: [String?]? = nil,
      recommendedPractice: [String?]? = nil,
      curriculumCode: String? = nil,
      curriculumStrand: String? = nil,
      curriculumSubStrand: String? = nil,
      curriculumTopicTitle: String? = nil,
      prerequisitesMastered: Bool? = nil,
      prerequisiteGaps: [String?]? = nil,
      curriculumMappedAt: Temporal.DateTime? = nil,
      calculatedAt: Temporal.DateTime,
      lastUpdatedAt: Temporal.DateTime,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.studentId = studentId
      self.classroomId = classroomId
      self.concept = concept
      self.gradeLevel = gradeLevel
      self.masteryPercentage = masteryPercentage
      self.accuracyRate = accuracyRate
      self.totalAttempts = totalAttempts
      self.correctAttempts = correctAttempts
      self.incorrectAttempts = incorrectAttempts
      self.trend = trend
      self.recentQuestions = recentQuestions
      self.lastPracticed = lastPracticed
      self.easyQuestions = easyQuestions
      self.mediumQuestions = mediumQuestions
      self.hardQuestions = hardQuestions
      self.easyCorrect = easyCorrect
      self.mediumCorrect = mediumCorrect
      self.hardCorrect = hardCorrect
      self.strengthAreas = strengthAreas
      self.improvementAreas = improvementAreas
      self.recommendedPractice = recommendedPractice
      self.curriculumCode = curriculumCode
      self.curriculumStrand = curriculumStrand
      self.curriculumSubStrand = curriculumSubStrand
      self.curriculumTopicTitle = curriculumTopicTitle
      self.prerequisitesMastered = prerequisitesMastered
      self.prerequisiteGaps = prerequisiteGaps
      self.curriculumMappedAt = curriculumMappedAt
      self.calculatedAt = calculatedAt
      self.lastUpdatedAt = lastUpdatedAt
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}