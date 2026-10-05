import Foundation

struct EchoEntry: Identifiable, Codable, Hashable, Sendable {
  let id: UUID
  let createdAt: Date
  private(set) var modifiedAt: Date
  let day: EchoDayIdentifier
  private(set) var rawText: String
  private(set) var polishedText: String?
  let type: EchoEntryType
  let source: EchoEntrySource

  init(
    id: UUID,
    createdAt: Date,
    modifiedAt: Date,
    day: EchoDayIdentifier,
    rawText: String,
    polishedText: String?,
    type: EchoEntryType,
    source: EchoEntrySource
  ) {
    self.id = id
    self.createdAt = createdAt
    self.modifiedAt = max(createdAt, modifiedAt)
    self.day = day
    self.rawText = rawText
    self.polishedText = polishedText
    self.type = type
    self.source = source
  }

  init(
    id: UUID = UUID(),
    createdAt: Date,
    modifiedAt: Date? = nil,
    calendar: Calendar,
    rawText: String,
    polishedText: String? = nil,
    type: EchoEntryType = .text,
    source: EchoEntrySource = .user
  ) {
    self.id = id
    self.createdAt = createdAt
    self.modifiedAt = max(createdAt, modifiedAt ?? createdAt)
    self.day = EchoDayIdentifier(containing: createdAt, calendar: calendar)
    self.rawText = rawText
    self.polishedText = polishedText
    self.type = type
    self.source = source
  }

  mutating func editRawText(_ text: String, at timestamp: Date) {
    rawText = text
    markModified(at: timestamp)
  }

  /// Stores assisted text separately; this operation never replaces `rawText`.
  mutating func setPolishedText(_ text: String?, at timestamp: Date) {
    polishedText = text
    markModified(at: timestamp)
  }

  private mutating func markModified(at timestamp: Date) {
    modifiedAt = max(modifiedAt, timestamp)
  }
}

enum EchoEntryOrdering {
  static func chronological(_ entries: [EchoEntry]) -> [EchoEntry] {
    entries.sorted { lhs, rhs in
      if lhs.createdAt != rhs.createdAt {
        return lhs.createdAt < rhs.createdAt
      }

      return lhs.id.uuidString < rhs.id.uuidString
    }
  }
}

struct EchoVoiceAttachment: Identifiable, Codable, Hashable, Sendable {
  let id: UUID
  let entryID: UUID
  let createdAt: Date
  let relativeFileName: String
  let duration: TimeInterval
  let format: String
  private(set) var transcript: String?

  init(
    id: UUID = UUID(),
    entryID: UUID,
    createdAt: Date,
    relativeFileName: String,
    duration: TimeInterval,
    format: String = "m4a",
    transcript: String? = nil
  ) {
    self.id = id
    self.entryID = entryID
    self.createdAt = createdAt
    self.relativeFileName = relativeFileName
    self.duration = max(0, duration)
    self.format = format
    self.transcript = transcript
  }

  mutating func setTranscript(_ transcript: String?) {
    self.transcript = transcript
  }
}
