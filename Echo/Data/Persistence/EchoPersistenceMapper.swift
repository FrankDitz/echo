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

  static func makeVoiceAttachmentRecord(
    from attachment: EchoVoiceAttachment
  ) -> PersistentEchoVoiceAttachment {
    PersistentEchoVoiceAttachment(
      id: attachment.id,
      entryID: attachment.entryID,
      createdAt: attachment.createdAt,
      relativeFileName: attachment.relativeFileName,
      duration: attachment.duration,
      format: attachment.format,
      transcript: attachment.transcript
    )
  }

  static func update(
    _ record: PersistentEchoVoiceAttachment,
    from attachment: EchoVoiceAttachment
  ) {
    record.entryID = attachment.entryID
    record.createdAt = attachment.createdAt
    record.relativeFileName = attachment.relativeFileName
    record.duration = attachment.duration
    record.format = attachment.format
    record.transcript = attachment.transcript
  }

  static func makeVoiceAttachment(
    from record: PersistentEchoVoiceAttachment
  ) -> EchoVoiceAttachment {
    EchoVoiceAttachment(
      id: record.id,
      entryID: record.entryID,
      createdAt: record.createdAt,
      relativeFileName: record.relativeFileName,
      duration: record.duration,
      format: record.format,
      transcript: record.transcript
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
  ) throws -> PersistentEchoOrganizedJournalV3 {
    let dayPayload = try encodeDay(journal.day)
    return PersistentEchoOrganizedJournalV3(
      id: journal.id,
      dayKey: dayPayload.base64EncodedString(),
      dayPayload: dayPayload,
      createdAt: journal.createdAt,
      modifiedAt: journal.modifiedAt,
      body: journal.body,
      title: journal.title,
      themesPayload: try encodeStrings(journal.themes),
      keyMomentsPayload: try encodeStrings(journal.keyMoments),
      reflectionQuestionsPayload: try encodeStrings(journal.reflectionQuestions),
      sourceEntryIDsPayload: try encodeEntryIDs(journal.sourceEntryIDs),
      generatorRawValue: journal.generator.rawValue
    )
  }

  static func update(
    _ record: PersistentEchoOrganizedJournalV3,
    from journal: EchoOrganizedJournal
  ) throws {
    let dayPayload = try encodeDay(journal.day)
    record.dayKey = dayPayload.base64EncodedString()
    record.dayPayload = dayPayload
    record.createdAt = journal.createdAt
    record.modifiedAt = journal.modifiedAt
    record.body = journal.body
    record.title = journal.title
    record.themesPayload = try encodeStrings(journal.themes)
    record.keyMomentsPayload = try encodeStrings(journal.keyMoments)
    record.reflectionQuestionsPayload = try encodeStrings(journal.reflectionQuestions)
    record.sourceEntryIDsPayload = try encodeEntryIDs(journal.sourceEntryIDs)
    record.generatorRawValue = journal.generator.rawValue
  }

  static func makeOrganizedJournal(
    from record: PersistentEchoOrganizedJournalV3
  ) throws -> EchoOrganizedJournal {
    EchoOrganizedJournal(
      id: record.id,
      day: try decodeDay(record.dayPayload),
      createdAt: record.createdAt,
      modifiedAt: record.modifiedAt,
      body: record.body,
      title: record.title,
      themes: try decodeStrings(record.themesPayload),
      keyMoments: try decodeStrings(record.keyMomentsPayload),
      reflectionQuestions: try decodeStrings(record.reflectionQuestionsPayload),
      sourceEntryIDs: try decodeEntryIDs(record.sourceEntryIDsPayload),
      generator: EchoJournalGenerator(rawValue: record.generatorRawValue)
    )
  }

  static func weekKey(for week: EchoWeekIdentifier) throws -> String {
    try encodeWeek(week).base64EncodedString()
  }

  static func makeWeeklyReflectionRecord(
    from reflection: EchoWeeklyReflection
  ) throws -> PersistentEchoWeeklyReflection {
    let weekPayload = try encodeWeek(reflection.week)
    return PersistentEchoWeeklyReflection(
      id: reflection.id,
      weekKey: weekPayload.base64EncodedString(),
      weekPayload: weekPayload,
      createdAt: reflection.createdAt,
      modifiedAt: reflection.modifiedAt,
      body: reflection.body,
      themesPayload: try encodeStrings(reflection.themes),
      notableEntryIDsPayload: try encodeEntryIDs(reflection.notableEntryIDs),
      sourceEntryIDsPayload: try encodeEntryIDs(reflection.sourceEntryIDs),
      question: reflection.question,
      generatorRawValue: reflection.generator.rawValue
    )
  }

  static func update(
    _ record: PersistentEchoWeeklyReflection,
    from reflection: EchoWeeklyReflection
  ) throws {
    let weekPayload = try encodeWeek(reflection.week)
    record.weekKey = weekPayload.base64EncodedString()
    record.weekPayload = weekPayload
    record.createdAt = reflection.createdAt
    record.modifiedAt = reflection.modifiedAt
    record.body = reflection.body
    record.themesPayload = try encodeStrings(reflection.themes)
    record.notableEntryIDsPayload = try encodeEntryIDs(reflection.notableEntryIDs)
    record.sourceEntryIDsPayload = try encodeEntryIDs(reflection.sourceEntryIDs)
    record.question = reflection.question
    record.generatorRawValue = reflection.generator.rawValue
  }

  static func makeWeeklyReflection(
    from record: PersistentEchoWeeklyReflection
  ) throws -> EchoWeeklyReflection {
    EchoWeeklyReflection(
      id: record.id,
      week: try decodeWeek(record.weekPayload),
      createdAt: record.createdAt,
      modifiedAt: record.modifiedAt,
      body: record.body,
      themes: try decodeStrings(record.themesPayload),
      notableEntryIDs: try decodeEntryIDs(record.notableEntryIDsPayload),
      sourceEntryIDs: try decodeEntryIDs(record.sourceEntryIDsPayload),
      question: record.question,
      generator: EchoJournalGenerator(rawValue: record.generatorRawValue)
    )
  }

  static func makeCarryForwardRecord(
    from carryForward: EchoCarryForward
  ) throws -> PersistentEchoCarryForward {
    let targetDayPayload = try encodeDay(carryForward.targetDay)
    let sourceDayPayload = try carryForward.sourceDay.map(encodeDay)
    return PersistentEchoCarryForward(
      id: carryForward.id,
      targetDayKey: targetDayPayload.base64EncodedString(),
      targetDayPayload: targetDayPayload,
      text: carryForward.text,
      sourceKindRawValue: carryForward.sourceKind.rawValue,
      sourceDayPayload: sourceDayPayload,
      sourceEntryID: carryForward.sourceEntryID,
      createdAt: carryForward.createdAt
    )
  }

  static func makeCarryForward(
    from record: PersistentEchoCarryForward
  ) throws -> EchoCarryForward {
    EchoCarryForward(
      id: record.id,
      text: record.text,
      sourceKind: EchoCarryForwardSourceKind(rawValue: record.sourceKindRawValue),
      sourceDay: try record.sourceDayPayload.map(decodeDay),
      sourceEntryID: record.sourceEntryID,
      targetDay: try decodeDay(record.targetDayPayload),
      createdAt: record.createdAt
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

  private static func encodeWeek(_ week: EchoWeekIdentifier) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return try encoder.encode(week)
  }

  private static func decodeWeek(_ data: Data) throws -> EchoWeekIdentifier {
    try JSONDecoder().decode(EchoWeekIdentifier.self, from: data)
  }

  private static func encodeEntryIDs(_ ids: [UUID]) throws -> Data {
    try JSONEncoder().encode(ids)
  }

  private static func decodeEntryIDs(_ data: Data) throws -> [UUID] {
    try JSONDecoder().decode([UUID].self, from: data)
  }

  private static func encodeStrings(_ values: [String]) throws -> Data {
    try JSONEncoder().encode(values)
  }

  private static func decodeStrings(_ data: Data?) throws -> [String] {
    guard let data else { return [] }
    return try JSONDecoder().decode([String].self, from: data)
  }
}
