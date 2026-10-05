import Foundation
import SwiftData

@Model
final class PersistentEchoEntry {
  @Attribute(.unique) var id: UUID
  var createdAt: Date
  var modifiedAt: Date
  var dayKey: String
  var dayPayload: Data
  var rawText: String
  var polishedText: String?
  var typeRawValue: String
  var sourceRawValue: String

  init(
    id: UUID,
    createdAt: Date,
    modifiedAt: Date,
    dayKey: String,
    dayPayload: Data,
    rawText: String,
    polishedText: String?,
    typeRawValue: String,
    sourceRawValue: String
  ) {
    self.id = id
    self.createdAt = createdAt
    self.modifiedAt = modifiedAt
    self.dayKey = dayKey
    self.dayPayload = dayPayload
    self.rawText = rawText
    self.polishedText = polishedText
    self.typeRawValue = typeRawValue
    self.sourceRawValue = sourceRawValue
  }
}

@Model
final class PersistentEchoVoiceAttachment {
  @Attribute(.unique) var id: UUID
  @Attribute(.unique) var entryID: UUID
  var createdAt: Date
  var relativeFileName: String
  var duration: TimeInterval
  var format: String
  var transcript: String?

  init(
    id: UUID,
    entryID: UUID,
    createdAt: Date,
    relativeFileName: String,
    duration: TimeInterval,
    format: String,
    transcript: String?
  ) {
    self.id = id
    self.entryID = entryID
    self.createdAt = createdAt
    self.relativeFileName = relativeFileName
    self.duration = duration
    self.format = format
    self.transcript = transcript
  }
}
