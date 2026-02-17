// swiftlint:disable all
import Amplify
import Foundation

public struct UserProfile: Model {
  public let id: String
  public var userId: String
  public var email: String
  public var userRole: UserRole
  public var displayName: String
  public var schoolName: String?
  public var gradeLevel: String?
  public var profileImageUrl: String?
  public var onboardingCompleted: Bool
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      userId: String,
      email: String,
      userRole: UserRole,
      displayName: String,
      schoolName: String? = nil,
      gradeLevel: String? = nil,
      profileImageUrl: String? = nil,
      onboardingCompleted: Bool) {
    self.init(id: id,
      userId: userId,
      email: email,
      userRole: userRole,
      displayName: displayName,
      schoolName: schoolName,
      gradeLevel: gradeLevel,
      profileImageUrl: profileImageUrl,
      onboardingCompleted: onboardingCompleted,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      userId: String,
      email: String,
      userRole: UserRole,
      displayName: String,
      schoolName: String? = nil,
      gradeLevel: String? = nil,
      profileImageUrl: String? = nil,
      onboardingCompleted: Bool,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.userId = userId
      self.email = email
      self.userRole = userRole
      self.displayName = displayName
      self.schoolName = schoolName
      self.gradeLevel = gradeLevel
      self.profileImageUrl = profileImageUrl
      self.onboardingCompleted = onboardingCompleted
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}