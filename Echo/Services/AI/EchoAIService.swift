import Foundation

struct EchoAssistedWriting: Equatable, Sendable {
  let text: String
}

struct EchoOrganizedJournalDraft: Equatable, Sendable {
  let day: EchoDayIdentifier
  let body: String
  let title: String?
  let themes: [String]
  let keyMoments: [String]
  let reflectionQuestions: [String]
  let sourceEntryIDs: [UUID]
}

struct EchoWeeklyReflectionDraft: Equatable, Sendable {
  let week: EchoWeekIdentifier
  let body: String
  let themes: [String]
  let notableEntryIDs: [UUID]
  let sourceEntryIDs: [UUID]
  let question: String?
}

enum EchoAIServiceError: Error, Equatable, Sendable {
  case emptyWriting
  case emptyDay
}

protocol EchoAIService: Sendable {
  func cleanUp(_ rawText: String) async throws -> EchoAssistedWriting
  func polish(_ rawText: String) async throws -> EchoAssistedWriting
  func organize(_ day: EchoDay) async throws -> EchoOrganizedJournalDraft
  func organizeWeek(
    entries: [EchoEntry],
    week: EchoWeekIdentifier
  ) async throws -> EchoWeeklyReflectionDraft
}
