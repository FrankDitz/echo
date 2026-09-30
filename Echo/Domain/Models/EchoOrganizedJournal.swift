import Foundation

struct EchoJournalGenerator: RawRepresentable, Codable, Hashable, Sendable {
  let rawValue: String

  static let deterministicLocal = EchoJournalGenerator(rawValue: "deterministic-local-v1")
}

struct EchoOrganizedJournal: Identifiable, Codable, Hashable, Sendable {
  let id: UUID
  let day: EchoDayIdentifier
  let createdAt: Date
  private(set) var modifiedAt: Date
  private(set) var body: String
  private(set) var sourceEntryIDs: [UUID]
  let generator: EchoJournalGenerator

  init(
    id: UUID = UUID(),
    day: EchoDayIdentifier,
    createdAt: Date,
    modifiedAt: Date? = nil,
    body: String,
    sourceEntryIDs: [UUID],
    generator: EchoJournalGenerator
  ) {
    self.id = id
    self.day = day
    self.createdAt = createdAt
    self.modifiedAt = max(createdAt, modifiedAt ?? createdAt)
    self.body = body
    self.sourceEntryIDs = sourceEntryIDs
    self.generator = generator
  }

  mutating func regenerate(
    body: String,
    sourceEntryIDs: [UUID],
    at timestamp: Date
  ) {
    self.body = body
    self.sourceEntryIDs = sourceEntryIDs
    modifiedAt = max(modifiedAt, timestamp)
  }
}
