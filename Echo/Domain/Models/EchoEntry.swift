import Foundation

enum EchoEntryRefinementStatus: String, Codable, Hashable, Sendable {
  case notRequested
  case processing
  case refined
  case needsReview
  case failed
}

struct EchoEntryRefinementProvenance: Codable, Hashable, Sendable {
  let processorIdentifier: String
  let modelIdentifier: String?
  let generatedAt: Date
}

struct EchoEntry: Identifiable, Codable, Hashable, Sendable {
  let id: UUID
  let createdAt: Date
  private(set) var modifiedAt: Date
  let day: EchoDayIdentifier
  let originalText: String
  private(set) var rawText: String
  private(set) var polishedText: String?
  private(set) var refinementStatus: EchoEntryRefinementStatus
  private(set) var refinementProvenance: EchoEntryRefinementProvenance?
  let type: EchoEntryType
  let source: EchoEntrySource

  private enum CodingKeys: String, CodingKey {
    case id
    case createdAt
    case modifiedAt
    case day
    case originalText
    case rawText
    case polishedText
    case refinementStatus
    case refinementProvenance
    case type
    case source
  }

  var preferredText: String {
    guard let polishedText,
      refinementStatus == .refined,
      polishedText.contains(where: { !$0.isWhitespace })
    else {
      return rawText
    }
    return polishedText
  }

  init(
    id: UUID,
    createdAt: Date,
    modifiedAt: Date,
    day: EchoDayIdentifier,
    rawText: String,
    polishedText: String?,
    originalText: String? = nil,
    refinementStatus: EchoEntryRefinementStatus? = nil,
    refinementProvenance: EchoEntryRefinementProvenance? = nil,
    type: EchoEntryType,
    source: EchoEntrySource
  ) {
    self.id = id
    self.createdAt = createdAt
    self.modifiedAt = max(createdAt, modifiedAt)
    self.day = day
    self.originalText = originalText ?? rawText
    self.rawText = rawText
    self.polishedText = polishedText
    self.refinementStatus = refinementStatus ?? (polishedText == nil ? .notRequested : .refined)
    self.refinementProvenance = refinementProvenance
    self.type = type
    self.source = source
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(UUID.self, forKey: .id)
    createdAt = try container.decode(Date.self, forKey: .createdAt)
    modifiedAt = max(
      createdAt,
      try container.decode(Date.self, forKey: .modifiedAt)
    )
    day = try container.decode(EchoDayIdentifier.self, forKey: .day)
    rawText = try container.decode(String.self, forKey: .rawText)
    originalText = try container.decodeIfPresent(String.self, forKey: .originalText) ?? rawText
    polishedText = try container.decodeIfPresent(String.self, forKey: .polishedText)
    refinementStatus =
      try container.decodeIfPresent(EchoEntryRefinementStatus.self, forKey: .refinementStatus)
      ?? (polishedText == nil ? .notRequested : .refined)
    refinementProvenance = try container.decodeIfPresent(
      EchoEntryRefinementProvenance.self,
      forKey: .refinementProvenance
    )
    type = try container.decode(EchoEntryType.self, forKey: .type)
    source = try container.decode(EchoEntrySource.self, forKey: .source)
  }

  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(createdAt, forKey: .createdAt)
    try container.encode(modifiedAt, forKey: .modifiedAt)
    try container.encode(day, forKey: .day)
    try container.encode(originalText, forKey: .originalText)
    try container.encode(rawText, forKey: .rawText)
    try container.encodeIfPresent(polishedText, forKey: .polishedText)
    try container.encode(refinementStatus, forKey: .refinementStatus)
    try container.encodeIfPresent(refinementProvenance, forKey: .refinementProvenance)
    try container.encode(type, forKey: .type)
    try container.encode(source, forKey: .source)
  }

  init(
    id: UUID = UUID(),
    createdAt: Date,
    modifiedAt: Date? = nil,
    calendar: Calendar,
    rawText: String,
    polishedText: String? = nil,
    originalText: String? = nil,
    refinementStatus: EchoEntryRefinementStatus? = nil,
    refinementProvenance: EchoEntryRefinementProvenance? = nil,
    type: EchoEntryType = .text,
    source: EchoEntrySource = .user
  ) {
    self.id = id
    self.createdAt = createdAt
    self.modifiedAt = max(createdAt, modifiedAt ?? createdAt)
    self.day = EchoDayIdentifier(containing: createdAt, calendar: calendar)
    self.originalText = originalText ?? rawText
    self.rawText = rawText
    self.polishedText = polishedText
    self.refinementStatus = refinementStatus ?? (polishedText == nil ? .notRequested : .refined)
    self.refinementProvenance = refinementProvenance
    self.type = type
    self.source = source
  }

  mutating func editRawText(_ text: String, at timestamp: Date) {
    rawText = text
    polishedText = nil
    refinementStatus = .notRequested
    refinementProvenance = nil
    markModified(at: timestamp)
  }

  /// Stores assisted text separately; this operation never replaces `rawText`.
  mutating func setPolishedText(_ text: String?, at timestamp: Date) {
    polishedText = text
    refinementStatus = text == nil ? .notRequested : .refined
    refinementProvenance = nil
    markModified(at: timestamp)
  }

  mutating func beginRefinement(at timestamp: Date) {
    refinementStatus = .processing
    markModified(at: timestamp)
  }

  mutating func completeRefinement(
    text: String,
    provenance: EchoEntryRefinementProvenance,
    requiresReview: Bool,
    at timestamp: Date
  ) {
    polishedText = text
    refinementStatus = requiresReview ? .needsReview : .refined
    refinementProvenance = provenance
    markModified(at: timestamp)
  }

  mutating func failRefinement(at timestamp: Date) {
    refinementStatus = .failed
    markModified(at: timestamp)
  }

  mutating func acceptRefinement(at timestamp: Date) {
    guard polishedText?.contains(where: { !$0.isWhitespace }) == true else { return }
    refinementStatus = .refined
    markModified(at: timestamp)
  }

  mutating func discardRefinement(at timestamp: Date) {
    polishedText = nil
    refinementStatus = .notRequested
    refinementProvenance = nil
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
