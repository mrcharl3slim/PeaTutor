// swiftlint:disable all
import Amplify
import Foundation

public enum UserRole: String, EnumPersistable {
  case teacher = "TEACHER"
  case student = "STUDENT"
  case parent = "PARENT"
}