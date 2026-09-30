import Foundation

protocol EchoOrganizedJournalRepository: Sendable {
  func create(_ journal: EchoOrganizedJournal) async throws
  func journal(for day: EchoDayIdentifier) async throws -> EchoOrganizedJournal?
  func allJournals() async throws -> [EchoOrganizedJournal]
  func update(_ journal: EchoOrganizedJournal) async throws
  func delete(id: UUID) async throws
}
