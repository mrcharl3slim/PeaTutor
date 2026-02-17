// swiftlint:disable all
import Amplify
import Foundation

public struct HomeworkSubmission: Model {
  public let id: String
  public var studentId: String
  public var status: SubmissionStatus
  public var submittedAt: Temporal.DateTime?
  public var worksheetId: String?
  public var score: Int?
  public var feedback: String?
  public var reviewedBy: String?
  public var reviewedAt: Temporal.DateTime?
  public var homework: Homework?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      studentId: String,
      status: SubmissionStatus,
      submittedAt: Temporal.DateTime? = nil,
      worksheetId: String? = nil,
      score: Int? = nil,
      feedback: String? = nil,
      reviewedBy: String? = nil,
      reviewedAt: Temporal.DateTime? = nil,
      homework: Homework? = nil) {
    self.init(id: id,
      studentId: studentId,
      status: status,
      submittedAt: submittedAt,
      worksheetId: worksheetId,
      score: score,
      feedback: feedback,
      reviewedBy: reviewedBy,
      reviewedAt: reviewedAt,
      homework: homework,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      studentId: String,
      status: SubmissionStatus,
      submittedAt: Temporal.DateTime? = nil,
      worksheetId: String? = nil,
      score: Int? = nil,
      feedback: String? = nil,
      reviewedBy: String? = nil,
      reviewedAt: Temporal.DateTime? = nil,
      homework: Homework? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.studentId = studentId
      self.status = status
      self.submittedAt = submittedAt
      self.worksheetId = worksheetId
      self.score = score
      self.feedback = feedback
      self.reviewedBy = reviewedBy
      self.reviewedAt = reviewedAt
      self.homework = homework
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}