import Foundation

enum EchoPersistenceMapper {
  static func makeEntryRecord(from entry: EchoEntry) throws -> PersistentEchoEntry {
    let dayPayload = try encodeDay(entry.day)
    return PersistentEchoEntry(
      id: entry.id,
      createdAt: entry.createdAt,
      modifiedAt: entry.modifiedAt,
      dayKey: dayPayload.base64EncodedString(),
      dayPayload: dayPayload,
      rawText: entry.rawText,
      polishedText: entry.polishedText,
      typeRawValue: entry.type.rawValue,
      sourceRawValue: entry.source.rawValue
    )
  }

  static func update(_ record: PersistentEchoEntry, from entry: EchoEntry) throws {
    let dayPayload = try encodeDay(entry.day)
    record.createdAt = entry.createdAt
    record.modifiedAt = entry.modifiedAt
    record.dayKey = dayPayload.base64EncodedString()
    record.dayPayload = dayPayload
    record.rawText = entry.rawText
    record.polishedText = entry.polishedText
    record.typeRawValue = entry.type.rawValue
    record.sourceRawValue = entry.source.rawValue
  }

  static func makeEntry(from record: PersistentEchoEntry) throws -> EchoEntry {
    EchoEntry(
      id: record.id,
      createdAt: record.createdAt,
      modifiedAt: record.modifiedAt,
      day: try decodeDay(record.dayPayload),
      rawText: record.rawText,
      polishedText: record.polishedText,
      type: EchoEntryType(rawValue: record.typeRawValue),
      source: EchoEntrySource(rawValue: record.sourceRawValue)
    )
  }

  static func dayKey(for day: EchoDayIdentifier) throws -> String {
    try encodeDay(day).base64EncodedString()
  }

  static func makeHighlightRecord(
    from highlight: EchoHighlight
  ) -> PersistentEchoHighlight {
    PersistentEchoHighlight(
      id: highlight.id,
      targetKindRawValue: highlight.target.kind.rawValue,
      targetEntityID: highlight.target.entityID,
      createdAt: highlight.createdAt
    )
  }

  static func makeHighlight(from record: PersistentEchoHighlight) -> EchoHighlight {
    EchoHighlight(
      id: record.id,
      target: EchoHighlightTarget(
        kind: EchoHighlightTargetKind(rawValue: record.targetKindRawValue),
        entityID: record.targetEntityID
      ),
      createdAt: record.createdAt
    )
  }

  static func makeOrganizedJournalRecord(
    from journal: EchoOrganizedJournal
  ) throws -> PersistentEchoOrganizedJournal {
    let dayPayload = try encodeDay(journal.day)
    return PersistentEchoOrganizedJournal(
      id: journal.id,
      dayKey: dayPayload.base64EncodedString(),
      dayPayload: dayPayload,
      createdAt: journal.createdAt,
      modifiedAt: journal.modifiedAt,
      body: journal.body,
      sourceEntryIDsPayload: try encodeEntryIDs(journal.sourceEntryIDs),
      generatorRawValue: journal.generator.rawValue
    )
  }

  static func update(
    _ record: PersistentEchoOrganizedJournal,
    from journal: EchoOrganizedJournal
  ) throws {
    let dayPayload = try encodeDay(journal.day)
    record.dayKey = dayPayload.base64EncodedString()
    record.dayPayload = dayPayload
    record.createdAt = journal.createdAt
    record.modifiedAt = journal.modifiedAt
    record.body = journal.body
    record.sourceEntryIDsPayload = try encodeEntryIDs(journal.sourceEntryIDs)
    record.generatorRawValue = journal.generator.rawValue
  }

  static func makeOrganizedJournal(
    from record: PersistentEchoOrganizedJournal
  ) throws -> EchoOrganizedJournal {
    EchoOrganizedJournal(
      id: record.id,
      day: try decodeDay(record.dayPayload),
      createdAt: record.createdAt,
      modifiedAt: record.modifiedAt,
      body: record.body,
      sourceEntryIDs: try decodeEntryIDs(record.sourceEntryIDsPayload),
      generator: EchoJournalGenerator(rawValue: record.generatorRawValue)
    )
  }

  private static func encodeDay(_ day: EchoDayIdentifier) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return try encoder.encode(day)
  }

  private static func decodeDay(_ data: Data) throws -> EchoDayIdentifier {
    try JSONDecoder().decode(EchoDayIdentifier.self, from: data)
  }

  private static func encodeEntryIDs(_ ids: [UUID]) throws -> Data {
    try JSONEncoder().encode(ids)
  }

  private static func decodeEntryIDs(_ data: Data) throws -> [UUID] {
    try JSONDecoder().decode([UUID].self, from: data)
  }
}
