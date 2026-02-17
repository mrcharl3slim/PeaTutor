// swiftlint:disable all
import Amplify
import Foundation

public enum RelationshipType: String, EnumPersistable {
  case parent = "PARENT"
  case guardian = "GUARDIAN"
  case tutor = "TUTOR"
}