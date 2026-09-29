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
