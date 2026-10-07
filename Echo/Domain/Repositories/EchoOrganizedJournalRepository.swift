import Foundation

protocol EchoOrganizedJournalRepository: Sendable {
  func create(_ journal: EchoOrganizedJournal) async throws
  func journal(for day: EchoDayIdentifier) async throws -> EchoOrganizedJournal?
  func allJournals() async throws -> [EchoOrganizedJournal]
  func update(_ journal: EchoOrganizedJournal) async throws
  func delete(id: UUID) async throws
}

protocol EchoWeeklyReflectionRepository: Sendable {
  func create(_ reflection: EchoWeeklyReflection) async throws
  func reflection(for week: EchoWeekIdentifier) async throws -> EchoWeeklyReflection?
  func allReflections() async throws -> [EchoWeeklyReflection]
  func update(_ reflection: EchoWeeklyReflection) async throws
  func delete(id: UUID) async throws
}

protocol EchoCarryForwardRepository: Sendable {
  func create(_ carryForward: EchoCarryForward) async throws
  func replace(_ carryForward: EchoCarryForward) async throws
  func carryForward(for targetDay: EchoDayIdentifier) async throws -> EchoCarryForward?
  func allCarryForwards() async throws -> [EchoCarryForward]
  func delete(id: UUID) async throws
}
