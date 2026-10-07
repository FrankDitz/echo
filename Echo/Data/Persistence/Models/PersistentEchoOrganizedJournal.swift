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

/// Version 3 uses a new entity so version 2 remains an immutable migration source.
@Model
final class PersistentEchoOrganizedJournalV3 {
  @Attribute(.unique) var id: UUID
  @Attribute(.unique) var dayKey: String
  var dayPayload: Data
  var createdAt: Date
  var modifiedAt: Date
  var body: String
  var title: String?
  var themesPayload: Data?
  var keyMomentsPayload: Data?
  var reflectionQuestionsPayload: Data?
  var sourceEntryIDsPayload: Data
  var generatorRawValue: String

  init(
    id: UUID,
    dayKey: String,
    dayPayload: Data,
    createdAt: Date,
    modifiedAt: Date,
    body: String,
    title: String? = nil,
    themesPayload: Data? = nil,
    keyMomentsPayload: Data? = nil,
    reflectionQuestionsPayload: Data? = nil,
    sourceEntryIDsPayload: Data,
    generatorRawValue: String
  ) {
    self.id = id
    self.dayKey = dayKey
    self.dayPayload = dayPayload
    self.createdAt = createdAt
    self.modifiedAt = modifiedAt
    self.body = body
    self.title = title
    self.themesPayload = themesPayload
    self.keyMomentsPayload = keyMomentsPayload
    self.reflectionQuestionsPayload = reflectionQuestionsPayload
    self.sourceEntryIDsPayload = sourceEntryIDsPayload
    self.generatorRawValue = generatorRawValue
  }
}

@Model
final class PersistentEchoWeeklyReflection {
  @Attribute(.unique) var id: UUID
  @Attribute(.unique) var weekKey: String
  var weekPayload: Data
  var createdAt: Date
  var modifiedAt: Date
  var body: String
  var themesPayload: Data
  var notableEntryIDsPayload: Data
  var sourceEntryIDsPayload: Data
  var question: String?
  var generatorRawValue: String

  init(
    id: UUID,
    weekKey: String,
    weekPayload: Data,
    createdAt: Date,
    modifiedAt: Date,
    body: String,
    themesPayload: Data,
    notableEntryIDsPayload: Data,
    sourceEntryIDsPayload: Data,
    question: String?,
    generatorRawValue: String
  ) {
    self.id = id
    self.weekKey = weekKey
    self.weekPayload = weekPayload
    self.createdAt = createdAt
    self.modifiedAt = modifiedAt
    self.body = body
    self.themesPayload = themesPayload
    self.notableEntryIDsPayload = notableEntryIDsPayload
    self.sourceEntryIDsPayload = sourceEntryIDsPayload
    self.question = question
    self.generatorRawValue = generatorRawValue
  }
}

@Model
final class PersistentEchoCarryForward {
  @Attribute(.unique) var id: UUID
  @Attribute(.unique) var targetDayKey: String
  var targetDayPayload: Data
  var text: String
  var sourceKindRawValue: String
  var sourceDayPayload: Data?
  var sourceEntryID: UUID?
  var createdAt: Date

  init(
    id: UUID,
    targetDayKey: String,
    targetDayPayload: Data,
    text: String,
    sourceKindRawValue: String,
    sourceDayPayload: Data?,
    sourceEntryID: UUID?,
    createdAt: Date
  ) {
    self.id = id
    self.targetDayKey = targetDayKey
    self.targetDayPayload = targetDayPayload
    self.text = text
    self.sourceKindRawValue = sourceKindRawValue
    self.sourceDayPayload = sourceDayPayload
    self.sourceEntryID = sourceEntryID
    self.createdAt = createdAt
  }
}
