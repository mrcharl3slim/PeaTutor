// swiftlint:disable all
import Amplify
import Foundation

public struct ParentChildRelationship: Model {
  public let id: String
  public var parentId: String
  public var childId: String
  public var linkingCode: String
  public var relationshipType: RelationshipType
  public var status: LinkStatus
  public var approvedAt: Temporal.DateTime?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      parentId: String,
      childId: String,
      linkingCode: String,
      relationshipType: RelationshipType,
      status: LinkStatus,
      approvedAt: Temporal.DateTime? = nil) {
    self.init(id: id,
      parentId: parentId,
      childId: childId,
      linkingCode: linkingCode,
      relationshipType: relationshipType,
      status: status,
      approvedAt: approvedAt,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      parentId: String,
      childId: String,
      linkingCode: String,
      relationshipType: RelationshipType,
      status: LinkStatus,
      approvedAt: Temporal.DateTime? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.parentId = parentId
      self.childId = childId
      self.linkingCode = linkingCode
      self.relationshipType = relationshipType
      self.status = status
      self.approvedAt = approvedAt
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}