// swiftlint:disable all
import Amplify
import Foundation

public enum SubmissionStatus: String, EnumPersistable {
  case notStarted = "NOT_STARTED"
  case inProgress = "IN_PROGRESS"
  case submitted = "SUBMITTED"
  case reviewed = "REVIEWED"
  case late = "LATE"
}