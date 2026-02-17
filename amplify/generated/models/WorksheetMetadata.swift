// swiftlint:disable all
import Amplify
import Foundation

public struct WorksheetMetadata: Model {
  public let id: String
  public var userId: String
  public var topics: [String]
  public var difficulty: String
  public var cognitiveSkills: [String]
  public var questionTypes: [String]
  public var estimatedTimeMinutes: Int?
  public var complexityLevel: String?
  public var commonCoreStandards: [String?]?
  public var bloomsTaxonomyLevels: [String?]?
  public var worksheet: Worksheet?
  public var curriculumCountry: String?
  public var curriculumVersion: String?
  public var moeCurriculumCodes: [String?]?
  public var detectedGradeLevel: String?
  public var detectedGradeLevelCode: String?
  public var curriculumStrand: String?
  public var curriculumSubStrand: String?
  public var curriculumConfidence: Double?
  public var curriculumMappedAt: Temporal.DateTime?
  public var extractedAt: Temporal.DateTime
  public var aiModel: String
  public var tokensUsed: Int?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      userId: String,
      topics: [String] = [],
      difficulty: String,
      cognitiveSkills: [String] = [],
      questionTypes: [String] = [],
      estimatedTimeMinutes: Int? = nil,
      complexityLevel: String? = nil,
      commonCoreStandards: [String?]? = nil,
      bloomsTaxonomyLevels: [String?]? = nil,
      worksheet: Worksheet? = nil,
      curriculumCountry: String? = nil,
      curriculumVersion: String? = nil,
      moeCurriculumCodes: [String?]? = nil,
      detectedGradeLevel: String? = nil,
      detectedGradeLevelCode: String? = nil,
      curriculumStrand: String? = nil,
      curriculumSubStrand: String? = nil,
      curriculumConfidence: Double? = nil,
      curriculumMappedAt: Temporal.DateTime? = nil,
      extractedAt: Temporal.DateTime,
      aiModel: String,
      tokensUsed: Int? = nil) {
    self.init(id: id,
      userId: userId,
      topics: topics,
      difficulty: difficulty,
      cognitiveSkills: cognitiveSkills,
      questionTypes: questionTypes,
      estimatedTimeMinutes: estimatedTimeMinutes,
      complexityLevel: complexityLevel,
      commonCoreStandards: commonCoreStandards,
      bloomsTaxonomyLevels: bloomsTaxonomyLevels,
      worksheet: worksheet,
      curriculumCountry: curriculumCountry,
      curriculumVersion: curriculumVersion,
      moeCurriculumCodes: moeCurriculumCodes,
      detectedGradeLevel: detectedGradeLevel,
      detectedGradeLevelCode: detectedGradeLevelCode,
      curriculumStrand: curriculumStrand,
      curriculumSubStrand: curriculumSubStrand,
      curriculumConfidence: curriculumConfidence,
      curriculumMappedAt: curriculumMappedAt,
      extractedAt: extractedAt,
      aiModel: aiModel,
      tokensUsed: tokensUsed,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      userId: String,
      topics: [String] = [],
      difficulty: String,
      cognitiveSkills: [String] = [],
      questionTypes: [String] = [],
      estimatedTimeMinutes: Int? = nil,
      complexityLevel: String? = nil,
      commonCoreStandards: [String?]? = nil,
      bloomsTaxonomyLevels: [String?]? = nil,
      worksheet: Worksheet? = nil,
      curriculumCountry: String? = nil,
      curriculumVersion: String? = nil,
      moeCurriculumCodes: [String?]? = nil,
      detectedGradeLevel: String? = nil,
      detectedGradeLevelCode: String? = nil,
      curriculumStrand: String? = nil,
      curriculumSubStrand: String? = nil,
      curriculumConfidence: Double? = nil,
      curriculumMappedAt: Temporal.DateTime? = nil,
      extractedAt: Temporal.DateTime,
      aiModel: String,
      tokensUsed: Int? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.userId = userId
      self.topics = topics
      self.difficulty = difficulty
      self.cognitiveSkills = cognitiveSkills
      self.questionTypes = questionTypes
      self.estimatedTimeMinutes = estimatedTimeMinutes
      self.complexityLevel = complexityLevel
      self.commonCoreStandards = commonCoreStandards
      self.bloomsTaxonomyLevels = bloomsTaxonomyLevels
      self.worksheet = worksheet
      self.curriculumCountry = curriculumCountry
      self.curriculumVersion = curriculumVersion
      self.moeCurriculumCodes = moeCurriculumCodes
      self.detectedGradeLevel = detectedGradeLevel
      self.detectedGradeLevelCode = detectedGradeLevelCode
      self.curriculumStrand = curriculumStrand
      self.curriculumSubStrand = curriculumSubStrand
      self.curriculumConfidence = curriculumConfidence
      self.curriculumMappedAt = curriculumMappedAt
      self.extractedAt = extractedAt
      self.aiModel = aiModel
      self.tokensUsed = tokensUsed
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}