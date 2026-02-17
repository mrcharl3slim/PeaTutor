// swiftlint:disable all
import Amplify
import Foundation

public struct CurriculumStandard: Model {
  public let id: String
  public var country: String
  public var curriculumName: String
  public var curriculumVersion: String
  public var gradeLevel: String
  public var gradeLevelCode: String
  public var strand: String
  public var strandCode: String
  public var subStrand: String
  public var subStrandCode: String
  public var topicNumber: String
  public var topicTitle: String
  public var subTopicCode: String
  public var subTopicDescription: String
  public var curriculumCode: String
  public var keywords: [String]
  public var sequenceOrder: Int
  public var prerequisiteCodes: [String?]?
  public var bulletPoints: [String?]?
  public var notes: String?
  public var isActive: Bool
  public var effectiveFrom: String?
  public var effectiveUntil: String?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      country: String,
      curriculumName: String,
      curriculumVersion: String,
      gradeLevel: String,
      gradeLevelCode: String,
      strand: String,
      strandCode: String,
      subStrand: String,
      subStrandCode: String,
      topicNumber: String,
      topicTitle: String,
      subTopicCode: String,
      subTopicDescription: String,
      curriculumCode: String,
      keywords: [String] = [],
      sequenceOrder: Int,
      prerequisiteCodes: [String?]? = nil,
      bulletPoints: [String?]? = nil,
      notes: String? = nil,
      isActive: Bool,
      effectiveFrom: String? = nil,
      effectiveUntil: String? = nil) {
    self.init(id: id,
      country: country,
      curriculumName: curriculumName,
      curriculumVersion: curriculumVersion,
      gradeLevel: gradeLevel,
      gradeLevelCode: gradeLevelCode,
      strand: strand,
      strandCode: strandCode,
      subStrand: subStrand,
      subStrandCode: subStrandCode,
      topicNumber: topicNumber,
      topicTitle: topicTitle,
      subTopicCode: subTopicCode,
      subTopicDescription: subTopicDescription,
      curriculumCode: curriculumCode,
      keywords: keywords,
      sequenceOrder: sequenceOrder,
      prerequisiteCodes: prerequisiteCodes,
      bulletPoints: bulletPoints,
      notes: notes,
      isActive: isActive,
      effectiveFrom: effectiveFrom,
      effectiveUntil: effectiveUntil,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      country: String,
      curriculumName: String,
      curriculumVersion: String,
      gradeLevel: String,
      gradeLevelCode: String,
      strand: String,
      strandCode: String,
      subStrand: String,
      subStrandCode: String,
      topicNumber: String,
      topicTitle: String,
      subTopicCode: String,
      subTopicDescription: String,
      curriculumCode: String,
      keywords: [String] = [],
      sequenceOrder: Int,
      prerequisiteCodes: [String?]? = nil,
      bulletPoints: [String?]? = nil,
      notes: String? = nil,
      isActive: Bool,
      effectiveFrom: String? = nil,
      effectiveUntil: String? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.country = country
      self.curriculumName = curriculumName
      self.curriculumVersion = curriculumVersion
      self.gradeLevel = gradeLevel
      self.gradeLevelCode = gradeLevelCode
      self.strand = strand
      self.strandCode = strandCode
      self.subStrand = subStrand
      self.subStrandCode = subStrandCode
      self.topicNumber = topicNumber
      self.topicTitle = topicTitle
      self.subTopicCode = subTopicCode
      self.subTopicDescription = subTopicDescription
      self.curriculumCode = curriculumCode
      self.keywords = keywords
      self.sequenceOrder = sequenceOrder
      self.prerequisiteCodes = prerequisiteCodes
      self.bulletPoints = bulletPoints
      self.notes = notes
      self.isActive = isActive
      self.effectiveFrom = effectiveFrom
      self.effectiveUntil = effectiveUntil
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}