// swiftlint:disable all
import Amplify
import Foundation

public enum MembershipStatus: String, EnumPersistable {
  case pending = "PENDING"
  case approved = "APPROVED"
  case rejected = "REJECTED"
  case inactive = "INACTIVE"
}