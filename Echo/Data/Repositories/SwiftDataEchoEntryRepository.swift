import Foundation
import SwiftData

@ModelActor
actor SwiftDataEchoEntryRepository: EchoEntryRepository {
  func create(_ entry: EchoEntry) async throws {
    guard try record(id: entry.id) == nil else {
      throw EchoRepositoryError.duplicateEntry(entry.id)
    }

    modelContext.insert(try EchoPersistenceMapper.makeEntryRecord(from: entry))
    try modelContext.save()
  }

  func entry(id: UUID) async throws -> EchoEntry? {
    try record(id: id).map(EchoPersistenceMapper.makeEntry)
  }

  func entries(for day: EchoDayIdentifier) async throws -> [EchoEntry] {
    let dayKey = try EchoPersistenceMapper.dayKey(for: day)
    let descriptor = FetchDescriptor<PersistentEchoEntry>(
      predicate: #Predicate { $0.dayKey == dayKey }
    )
    let entries = try modelContext.fetch(descriptor).map(EchoPersistenceMapper.makeEntry)
    return EchoEntryOrdering.chronological(entries)
  }

  func allEntries() async throws -> [EchoEntry] {
    let entries = try modelContext.fetch(FetchDescriptor<PersistentEchoEntry>())
      .map(EchoPersistenceMapper.makeEntry)
    return EchoEntryOrdering.chronological(entries)
  }

  func searchEntries(matching query: EchoEntrySearchQuery) async throws -> [EchoEntry] {
    guard !query.isEmpty else { return [] }

    // Search remains inside the existing app-container store. Echo does not create
    // a second index, export journal text, or expose content to system search.
    let entries = try modelContext.fetch(FetchDescriptor<PersistentEchoEntry>())
      .map(EchoPersistenceMapper.makeEntry)
      .filter(query.matches)

    return entries.sorted { lhs, rhs in
      if lhs.createdAt != rhs.createdAt {
        return lhs.createdAt > rhs.createdAt
      }
      return lhs.id.uuidString < rhs.id.uuidString
    }
  }

  func update(_ entry: EchoEntry) async throws {
    guard let record = try record(id: entry.id) else {
      throw EchoRepositoryError.entryNotFound(entry.id)
    }

    try EchoPersistenceMapper.update(record, from: entry)
    try modelContext.save()
  }

  func delete(id: UUID) async throws {
    guard let record = try record(id: id) else {
      throw EchoRepositoryError.entryNotFound(id)
    }

    modelContext.delete(record)
    try modelContext.save()
  }

  private func record(id: UUID) throws -> PersistentEchoEntry? {
    var descriptor = FetchDescriptor<PersistentEchoEntry>(
      predicate: #Predicate { $0.id == id }
    )
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first
  }
}
