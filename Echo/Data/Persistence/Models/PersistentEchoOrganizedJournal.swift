import Foundation
import SwiftData

@Model
final class PersistentEchoOrganizedJournal {
  @Attribute(.unique) var id: UUID
  @Attribute(.unique) var dayKey: String
  var dayPayload: Data
  var createdAt: Date
  var modifiedAt: Date
  var body: String
  var sourceEntryIDsPayload: Data
  var generatorRawValue: String

  init(
    id: UUID,
    dayKey: String,
    dayPayload: Data,
    createdAt: Date,
    modifiedAt: Date,
    body: String,
    sourceEntryIDsPayload: Data,
    generatorRawValue: String
  ) {
    self.id = id
    self.dayKey = dayKey
    self.dayPayload = dayPayload
    self.createdAt = createdAt
    self.modifiedAt = modifiedAt
    self.body = body
    self.sourceEntryIDsPayload = sourceEntryIDsPayload
    self.generatorRawValue = generatorRawValue
  }
}
