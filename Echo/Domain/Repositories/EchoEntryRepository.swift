import Foundation

protocol EchoEntryRepository: Sendable {
  func create(_ entry: EchoEntry) async throws
  func entry(id: UUID) async throws -> EchoEntry?
  func entries(for day: EchoDayIdentifier) async throws -> [EchoEntry]
  func allEntries() async throws -> [EchoEntry]
  func update(_ entry: EchoEntry) async throws
  func delete(id: UUID) async throws
}
