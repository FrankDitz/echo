import Foundation
import SwiftData

@Model
final class PersistentEchoHighlight {
  @Attribute(.unique) var id: UUID
  var targetKindRawValue: String
  var targetEntityID: UUID
  var createdAt: Date

  init(
    id: UUID,
    targetKindRawValue: String,
    targetEntityID: UUID,
    createdAt: Date
  ) {
    self.id = id
    self.targetKindRawValue = targetKindRawValue
    self.targetEntityID = targetEntityID
    self.createdAt = createdAt
  }
}
