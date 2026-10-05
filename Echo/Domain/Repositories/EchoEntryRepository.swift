import Foundation

struct EchoEntrySearchQuery: Equatable, Sendable {
  let terms: [String]

  init(_ text: String) {
    terms = text
      .split(whereSeparator: \.isWhitespace)
      .map { Self.normalize(String($0)) }
      .filter { !$0.isEmpty }
  }

  var isEmpty: Bool { terms.isEmpty }

  func matches(_ entry: EchoEntry) -> Bool {
    guard !isEmpty else { return false }

    let searchableText = Self.normalize(
      [entry.rawText, entry.polishedText]
        .compactMap { $0 }
        .joined(separator: "\n")
    )
    return terms.allSatisfy(searchableText.contains)
  }

  private static func normalize(_ text: String) -> String {
    text.folding(
      options: [.caseInsensitive, .diacriticInsensitive],
      locale: Locale(identifier: "en_US_POSIX")
    )
  }
}

protocol EchoEntryRepository: Sendable {
  func create(_ entry: EchoEntry) async throws
  func entry(id: UUID) async throws -> EchoEntry?
  func entries(for day: EchoDayIdentifier) async throws -> [EchoEntry]
  func allEntries() async throws -> [EchoEntry]
  func searchEntries(matching query: EchoEntrySearchQuery) async throws -> [EchoEntry]
  func update(_ entry: EchoEntry) async throws
  func delete(id: UUID) async throws
}

protocol EchoVoiceAttachmentRepository: Sendable {
  func create(_ attachment: EchoVoiceAttachment) async throws
  func attachment(for entryID: UUID) async throws -> EchoVoiceAttachment?
  func allAttachments() async throws -> [EchoVoiceAttachment]
  func update(_ attachment: EchoVoiceAttachment) async throws
  func delete(id: UUID) async throws
}

extension EchoEntryRepository {
  func searchEntries(matching query: EchoEntrySearchQuery) async throws -> [EchoEntry] {
    guard !query.isEmpty else { return [] }
    return try await allEntries()
      .filter(query.matches)
      .sorted(by: newestEntryFirst)
  }

  private func newestEntryFirst(_ lhs: EchoEntry, _ rhs: EchoEntry) -> Bool {
    if lhs.createdAt != rhs.createdAt {
      return lhs.createdAt > rhs.createdAt
    }
    return lhs.id.uuidString < rhs.id.uuidString
  }
}
