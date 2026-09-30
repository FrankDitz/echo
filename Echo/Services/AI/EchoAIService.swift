import Foundation

struct EchoAssistedWriting: Equatable, Sendable {
  let text: String
}

struct EchoOrganizedJournalDraft: Equatable, Sendable {
  let day: EchoDayIdentifier
  let body: String
  let sourceEntryIDs: [UUID]
}

enum EchoAIServiceError: Error, Equatable, Sendable {
  case emptyWriting
  case emptyDay
}

protocol EchoAIService: Sendable {
  func cleanUp(_ rawText: String) async throws -> EchoAssistedWriting
  func polish(_ rawText: String) async throws -> EchoAssistedWriting
  func organize(_ day: EchoDay) async throws -> EchoOrganizedJournalDraft
}
