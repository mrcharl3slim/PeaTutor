// swiftlint:disable all
import Amplify
import Foundation

public struct StudentAnalyticsSummary: Model {
  public let id: String
  public var studentId: String
  public var classroomId: String?
  public var overallProgress: Double
  public var totalQuestionsAttempted: Int
  public var totalQuestionsCorrect: Int
  public var overallAccuracy: Double
  public var masteredConcepts: [String]
  public var developingConcepts: [String]
  public var needsWorkConcepts: [String]
  public var topStrengths: [String]
  public var topWeaknesses: [String]
  public var mostCommonErrors: [String]
  public var highSeverityErrorCount: Int
  public var mediumSeverityErrorCount: Int
  public var currentStreak: Int
  public var longestStreak: Int
  public var practiceFrequency: String
  public var computationScore: Double
  public var problemSolvingScore: Double
  public var reasoningScore: Double
  public var accuracyScore: Double
  public var wordProblemScore: Double
  public var lastCalculated: Temporal.DateTime
  public var lastUpdated: Temporal.DateTime
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      studentId: String,
      classroomId: String? = nil,
      overallProgress: Double,
      totalQuestionsAttempted: Int,
      totalQuestionsCorrect: Int,
      overallAccuracy: Double,
      masteredConcepts: [String] = [],
      developingConcepts: [String] = [],
      needsWorkConcepts: [String] = [],
      topStrengths: [String] = [],
      topWeaknesses: [String] = [],
      mostCommonErrors: [String] = [],
      highSeverityErrorCount: Int,
      mediumSeverityErrorCount: Int,
      currentStreak: Int,
      longestStreak: Int,
      practiceFrequency: String,
      computationScore: Double,
      problemSolvingScore: Double,
      reasoningScore: Double,
      accuracyScore: Double,
      wordProblemScore: Double,
      lastCalculated: Temporal.DateTime,
      lastUpdated: Temporal.DateTime) {
    self.init(id: id,
      studentId: studentId,
      classroomId: classroomId,
      overallProgress: overallProgress,
      totalQuestionsAttempted: totalQuestionsAttempted,
      totalQuestionsCorrect: totalQuestionsCorrect,
      overallAccuracy: overallAccuracy,
      masteredConcepts: masteredConcepts,
      developingConcepts: developingConcepts,
      needsWorkConcepts: needsWorkConcepts,
      topStrengths: topStrengths,
      topWeaknesses: topWeaknesses,
      mostCommonErrors: mostCommonErrors,
      highSeverityErrorCount: highSeverityErrorCount,
      mediumSeverityErrorCount: mediumSeverityErrorCount,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      practiceFrequency: practiceFrequency,
      computationScore: computationScore,
      problemSolvingScore: problemSolvingScore,
      reasoningScore: reasoningScore,
      accuracyScore: accuracyScore,
      wordProblemScore: wordProblemScore,
      lastCalculated: lastCalculated,
      lastUpdated: lastUpdated,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      studentId: String,
      classroomId: String? = nil,
      overallProgress: Double,
      totalQuestionsAttempted: Int,
      totalQuestionsCorrect: Int,
      overallAccuracy: Double,
      masteredConcepts: [String] = [],
      developingConcepts: [String] = [],
      needsWorkConcepts: [String] = [],
      topStrengths: [String] = [],
      topWeaknesses: [String] = [],
      mostCommonErrors: [String] = [],
      highSeverityErrorCount: Int,
      mediumSeverityErrorCount: Int,
      currentStreak: Int,
      longestStreak: Int,
      practiceFrequency: String,
      computationScore: Double,
      problemSolvingScore: Double,
      reasoningScore: Double,
      accuracyScore: Double,
      wordProblemScore: Double,
      lastCalculated: Temporal.DateTime,
      lastUpdated: Temporal.DateTime,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.studentId = studentId
      self.classroomId = classroomId
      self.overallProgress = overallProgress
      self.totalQuestionsAttempted = totalQuestionsAttempted
      self.totalQuestionsCorrect = totalQuestionsCorrect
      self.overallAccuracy = overallAccuracy
      self.masteredConcepts = masteredConcepts
      self.developingConcepts = developingConcepts
      self.needsWorkConcepts = needsWorkConcepts
      self.topStrengths = topStrengths
      self.topWeaknesses = topWeaknesses
      self.mostCommonErrors = mostCommonErrors
      self.highSeverityErrorCount = highSeverityErrorCount
      self.mediumSeverityErrorCount = mediumSeverityErrorCount
      self.currentStreak = currentStreak
      self.longestStreak = longestStreak
      self.practiceFrequency = practiceFrequency
      self.computationScore = computationScore
      self.problemSolvingScore = problemSolvingScore
      self.reasoningScore = reasoningScore
      self.accuracyScore = accuracyScore
      self.wordProblemScore = wordProblemScore
      self.lastCalculated = lastCalculated
      self.lastUpdated = lastUpdated
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}