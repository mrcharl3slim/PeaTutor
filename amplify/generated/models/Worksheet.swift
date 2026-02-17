// swiftlint:disable all
import Amplify
import Foundation

public struct Worksheet: Model {
  public let id: String
  public var userId: String
  public var title: String
  public var fileType: String?
  public var fileName: String
  public var s3WorksheetKey: String
  public var extractionResult: String?
  public var questionCount: Int?
  public var totalMarks: Int?
  public var uploadedAt: Temporal.DateTime
  public var fileSize: Int?
  public var contentHash: String?
  public var sourceFileHashes: [String?]?
  public var lastAccessedAt: Temporal.DateTime?
  public var questions: List<Question>?
  public var fullWorksheetSolutions: List<FullWorksheetSolution>?
  public var homeworkAssignments: List<Homework>?
  public var metadata: List<WorksheetMetadata>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      userId: String,
      title: String,
      fileType: String? = nil,
      fileName: String,
      s3WorksheetKey: String,
      extractionResult: String? = nil,
      questionCount: Int? = nil,
      totalMarks: Int? = nil,
      uploadedAt: Temporal.DateTime,
      fileSize: Int? = nil,
      contentHash: String? = nil,
      sourceFileHashes: [String?]? = nil,
      lastAccessedAt: Temporal.DateTime? = nil,
      questions: List<Question>? = [],
      fullWorksheetSolutions: List<FullWorksheetSolution>? = [],
      homeworkAssignments: List<Homework>? = [],
      metadata: List<WorksheetMetadata>? = []) {
    self.init(id: id,
      userId: userId,
      title: title,
      fileType: fileType,
      fileName: fileName,
      s3WorksheetKey: s3WorksheetKey,
      extractionResult: extractionResult,
      questionCount: questionCount,
      totalMarks: totalMarks,
      uploadedAt: uploadedAt,
      fileSize: fileSize,
      contentHash: contentHash,
      sourceFileHashes: sourceFileHashes,
      lastAccessedAt: lastAccessedAt,
      questions: questions,
      fullWorksheetSolutions: fullWorksheetSolutions,
      homeworkAssignments: homeworkAssignments,
      metadata: metadata,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      userId: String,
      title: String,
      fileType: String? = nil,
      fileName: String,
      s3WorksheetKey: String,
      extractionResult: String? = nil,
      questionCount: Int? = nil,
      totalMarks: Int? = nil,
      uploadedAt: Temporal.DateTime,
      fileSize: Int? = nil,
      contentHash: String? = nil,
      sourceFileHashes: [String?]? = nil,
      lastAccessedAt: Temporal.DateTime? = nil,
      questions: List<Question>? = [],
      fullWorksheetSolutions: List<FullWorksheetSolution>? = [],
      homeworkAssignments: List<Homework>? = [],
      metadata: List<WorksheetMetadata>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.userId = userId
      self.title = title
      self.fileType = fileType
      self.fileName = fileName
      self.s3WorksheetKey = s3WorksheetKey
      self.extractionResult = extractionResult
      self.questionCount = questionCount
      self.totalMarks = totalMarks
      self.uploadedAt = uploadedAt
      self.fileSize = fileSize
      self.contentHash = contentHash
      self.sourceFileHashes = sourceFileHashes
      self.lastAccessedAt = lastAccessedAt
      self.questions = questions
      self.fullWorksheetSolutions = fullWorksheetSolutions
      self.homeworkAssignments = homeworkAssignments
      self.metadata = metadata
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}