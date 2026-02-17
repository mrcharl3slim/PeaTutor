// swiftlint:disable all
import Amplify
import Foundation

public struct CurriculumTopicSummary: Model {
  public let id: String
  public var country: String
  public var curriculumVersion: String
  public var gradeLevel: String
  public var gradeLevelCode: String
  public var strand: String
  public var strandCode: String
  public var subStrand: String
  public var subStrandCode: String
  public var topicNumber: String
  public var topicTitle: String
  public var topicCode: String
  public var subTopicCount: Int
  public var subTopicCodes: [String]
  public var allKeywords: [String]
  public var sequenceOrder: Int
  public var isActive: Bool
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      country: String,
      curriculumVersion: String,
      gradeLevel: String,
      gradeLevelCode: String,
      strand: String,
      strandCode: String,
      subStrand: String,
      subStrandCode: String,
      topicNumber: String,
      topicTitle: String,
      topicCode: String,
      subTopicCount: Int,
      subTopicCodes: [String] = [],
      allKeywords: [String] = [],
      sequenceOrder: Int,
      isActive: Bool) {
    self.init(id: id,
      country: country,
      curriculumVersion: curriculumVersion,
      gradeLevel: gradeLevel,
      gradeLevelCode: gradeLevelCode,
      strand: strand,
      strandCode: strandCode,
      subStrand: subStrand,
      subStrandCode: subStrandCode,
      topicNumber: topicNumber,
      topicTitle: topicTitle,
      topicCode: topicCode,
      subTopicCount: subTopicCount,
      subTopicCodes: subTopicCodes,
      allKeywords: allKeywords,
      sequenceOrder: sequenceOrder,
      isActive: isActive,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      country: String,
      curriculumVersion: String,
      gradeLevel: String,
      gradeLevelCode: String,
      strand: String,
      strandCode: String,
      subStrand: String,
      subStrandCode: String,
      topicNumber: String,
      topicTitle: String,
      topicCode: String,
      subTopicCount: Int,
      subTopicCodes: [String] = [],
      allKeywords: [String] = [],
      sequenceOrder: Int,
      isActive: Bool,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.country = country
      self.curriculumVersion = curriculumVersion
      self.gradeLevel = gradeLevel
      self.gradeLevelCode = gradeLevelCode
      self.strand = strand
      self.strandCode = strandCode
      self.subStrand = subStrand
      self.subStrandCode = subStrandCode
      self.topicNumber = topicNumber
      self.topicTitle = topicTitle
      self.topicCode = topicCode
      self.subTopicCount = subTopicCount
      self.subTopicCodes = subTopicCodes
      self.allKeywords = allKeywords
      self.sequenceOrder = sequenceOrder
      self.isActive = isActive
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}