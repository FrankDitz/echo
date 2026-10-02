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
  private(set) var title: String?
  private(set) var themes: [String]
  private(set) var keyMoments: [String]
  private(set) var reflectionQuestions: [String]
  private(set) var sourceEntryIDs: [UUID]
  let generator: EchoJournalGenerator

  init(
    id: UUID = UUID(),
    day: EchoDayIdentifier,
    createdAt: Date,
    modifiedAt: Date? = nil,
    body: String,
    title: String? = nil,
    themes: [String] = [],
    keyMoments: [String] = [],
    reflectionQuestions: [String] = [],
    sourceEntryIDs: [UUID],
    generator: EchoJournalGenerator
  ) {
    self.id = id
    self.day = day
    self.createdAt = createdAt
    self.modifiedAt = max(createdAt, modifiedAt ?? createdAt)
    self.body = body
    self.title = title
    self.themes = themes
    self.keyMoments = keyMoments
    self.reflectionQuestions = reflectionQuestions
    self.sourceEntryIDs = sourceEntryIDs
    self.generator = generator
  }

  mutating func regenerate(
    body: String,
    title: String? = nil,
    themes: [String] = [],
    keyMoments: [String] = [],
    reflectionQuestions: [String] = [],
    sourceEntryIDs: [UUID],
    at timestamp: Date
  ) {
    self.body = body
    self.title = title
    self.themes = themes
    self.keyMoments = keyMoments
    self.reflectionQuestions = reflectionQuestions
    self.sourceEntryIDs = sourceEntryIDs
    modifiedAt = max(modifiedAt, timestamp)
  }

  private enum CodingKeys: String, CodingKey {
    case id, day, createdAt, modifiedAt, body, title, themes, keyMoments
    case reflectionQuestions, sourceEntryIDs, generator
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(UUID.self, forKey: .id)
    day = try container.decode(EchoDayIdentifier.self, forKey: .day)
    createdAt = try container.decode(Date.self, forKey: .createdAt)
    modifiedAt = try container.decode(Date.self, forKey: .modifiedAt)
    body = try container.decode(String.self, forKey: .body)
    title = try container.decodeIfPresent(String.self, forKey: .title)
    themes = try container.decodeIfPresent([String].self, forKey: .themes) ?? []
    keyMoments = try container.decodeIfPresent([String].self, forKey: .keyMoments) ?? []
    reflectionQuestions = try container.decodeIfPresent(
      [String].self,
      forKey: .reflectionQuestions
    ) ?? []
    sourceEntryIDs = try container.decode([UUID].self, forKey: .sourceEntryIDs)
    generator = try container.decode(EchoJournalGenerator.self, forKey: .generator)
  }
}
