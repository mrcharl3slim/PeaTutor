// swiftlint:disable all
import Amplify
import Foundation

public enum LinkStatus: String, EnumPersistable {
  case pending = "PENDING"
  case approved = "APPROVED"
  case rejected = "REJECTED"
  case revoked = "REVOKED"
}